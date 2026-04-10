codeunit 134267 "Payment Proposal UT"
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
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        CannotChangeAppliedLineErr: Label 'You cannot change the line because the entry is applied. Remove the applied entry first.';
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
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Payment Proposal UT");

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

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Payment Proposal UT");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERM.FindZeroVATPostingSetup(ZeroVATPostingSetup, ZeroVATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Commit();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Payment Proposal UT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplied_OnCrMemo()
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
    begin
        Initialize();

        // General Setup:
        // * Populate Bank Acc. Reconciliation Line with dummy line
        // * Populate Payment Application Proposal with dummy line (2 Inv and 2 CrMemo)
        PopulateBankAccReconLine(BankAccReconLine);
        PopulatePaymentApplicationProposal(BankAccReconLine, TempPaymentApplicationProposal);

        // validate Applied on CrMemo
        TempPaymentApplicationProposal.SetRange("Document Type", TempPaymentApplicationProposal."Document Type"::"Credit Memo");
        TempPaymentApplicationProposal.FindFirst();
        TempPaymentApplicationProposal.Validate(Applied, true);

        // Result - It's applied.
        Assert.AreNotEqual(0, TempPaymentApplicationProposal."Applied Amount", 'Application for single Cr.Memo.');
    end;

    [Test]
    [HandlerFunctions('MsgWantToApplyCreditMemoAndInvoices')]
    [Scope('OnPrem')]
    procedure TestApplied_OnCrMemo_WithInv()
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
    begin
        Initialize();

        // General Setup:
        // * Populate Bank Acc. Reconciliation Line with dummy line
        // * Populate Payment Application Proposal with dummy line (2 Inv and 2 CrMemo)
        PopulateBankAccReconLine(BankAccReconLine);
        PopulatePaymentApplicationProposal(BankAccReconLine, TempPaymentApplicationProposal);

        // Apply Inv
        TempPaymentApplicationProposal.SetRange("Document Type", TempPaymentApplicationProposal."Document Type"::Invoice);
        TempPaymentApplicationProposal.FindFirst();
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify();

        // validate Applied on CrMemo
        TempPaymentApplicationProposal.SetRange("Document Type", TempPaymentApplicationProposal."Document Type"::"Credit Memo");
        TempPaymentApplicationProposal.FindFirst();
        TempPaymentApplicationProposal.Validate(Applied, true);

        // Result - Msg
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplied_OnCrMemo_WithInvAndCrMemo()
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
    begin
        Initialize();

        // General Setup:
        // * Populate Bank Acc. Reconciliation Line with dummy line
        // * Populate Payment Application Proposal with dummy line (2 Inv and 2 CrMemo)
        PopulateBankAccReconLine(BankAccReconLine);
        PopulatePaymentApplicationProposal(BankAccReconLine, TempPaymentApplicationProposal);

        // Apply Inv & CrMemo
        TempPaymentApplicationProposal.SetRange("Document Type", TempPaymentApplicationProposal."Document Type"::"Credit Memo");
        TempPaymentApplicationProposal.FindFirst();
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify();

        TempPaymentApplicationProposal.SetRange("Document Type", TempPaymentApplicationProposal."Document Type"::Invoice);
        TempPaymentApplicationProposal.FindFirst();
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify();

        // validate Applied on CrMemo
        TempPaymentApplicationProposal.SetRange("Document Type", TempPaymentApplicationProposal."Document Type"::"Credit Memo");
        TempPaymentApplicationProposal.FindLast();
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify();

        // Result - Ok
        Assert.AreNotEqual(0, TempPaymentApplicationProposal."Applied Amount", 'Application for second Cr.Memo.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplied_ToInv_WheneTherIsNothingToApplyLeft()
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
    begin
        Initialize();

        // General Setup:
        // * Populate Bank Acc. Reconciliation Line with dummy line
        // * Populate Payment Application Proposal with dummy line (2 Inv and 2 CrMemo)
        PopulateBankAccReconLine(BankAccReconLine);
        PopulatePaymentApplicationProposal(BankAccReconLine, TempPaymentApplicationProposal);

        BankAccReconLine.Difference := 0;
        BankAccReconLine.Modify();

        // Apply Inv
        TempPaymentApplicationProposal.SetRange("Document Type", TempPaymentApplicationProposal."Document Type"::Invoice);
        TempPaymentApplicationProposal.FindFirst();
        asserterror TempPaymentApplicationProposal.Validate(Applied, true);
        // Result - Error
        Assert.ExpectedError('The payment is fully applied.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplied_ToInv_Sunshine()
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
    begin
        Initialize();

        // General Setup:
        // * Populate Bank Acc. Reconciliation Line with dummy line
        // * Populate Payment Application Proposal with dummy line (2 Inv and 2 CrMemo)
        PopulateBankAccReconLine(BankAccReconLine);
        PopulatePaymentApplicationProposal(BankAccReconLine, TempPaymentApplicationProposal);

        // Apply Inv
        TempPaymentApplicationProposal.SetRange("Document Type", TempPaymentApplicationProposal."Document Type"::Invoice);
        TempPaymentApplicationProposal.FindFirst();
        TempPaymentApplicationProposal.Validate(Applied, true);

        // Result - Ok
        Assert.AreNotEqual(0, TempPaymentApplicationProposal."Applied Amount", 'Application for single Inv.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSuggestAmtToApply_OnCustCrMemo()
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SuggestAmt: Decimal;
    begin
        Initialize();

        // General Setup:
        // * Populate Bank Acc. Reconciliation Line with dummy line
        // * Populate Payment Application Proposal with dummy line (2 Inv and 2 CrMemo)
        PopulateBankAccReconLine(BankAccReconLine);
        PopulateAppliedPaymentEntry(BankAccReconLine, AppliedPaymentEntry);

        SuggestAmt := AppliedPaymentEntry.SuggestAmtToApply();

        // Result - it will return RemAmtToApply
        CustLedgerEntry.FindLast();
        CustLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreEqual(CustLedgerEntry."Remaining Amount", SuggestAmt, 'Wrong sugested amount.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPaymentProposalFieldsMatchAppliedEntryFields()
    var
        AppliedPaymentEntryRecRef: RecordRef;
        PaymentApplicationProposalRecRef: RecordRef;
        CommonFieldsFieldRef: array[18] of FieldRef;
        PaymentProposalSpecificFieldRef: array[10] of FieldRef;
    begin
        GetCommonFields(CommonFieldsFieldRef);
        AppliedPaymentEntryRecRef.Open(DATABASE::"Applied Payment Entry");

        // Verify definitions match
        VerifyFieldDefinitionsMatchTableFields(AppliedPaymentEntryRecRef, CommonFieldsFieldRef);

        // Verify no Unaccounted fileds found in two tables
        Assert.AreEqual(AppliedPaymentEntryRecRef.FieldCount, ArrayLen(CommonFieldsFieldRef),
          'There are extra fields in Applied Payment Entry Table please verify if they should be moved to Payment Proposal table and update the test');

        PaymentApplicationProposalRecRef.Open(DATABASE::"Payment Application Proposal");
        GetPaymentProposalSpecificFields(PaymentProposalSpecificFieldRef);

        Assert.AreEqual(
          PaymentApplicationProposalRecRef.FieldCount, ArrayLen(CommonFieldsFieldRef) + ArrayLen(PaymentProposalSpecificFieldRef),
          'There are extra fields in Payment Proposal table please verify if they should be moved to Payment Proposal table and update the test');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPaymentProposalSpecificFields()
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
        AppliedPaymentEntryRecRef: RecordRef;
        PaymentProposalSpecificFieldRef: array[10] of FieldRef;
    begin
        GetPaymentProposalSpecificFields(PaymentProposalSpecificFieldRef);
        AppliedPaymentEntry.Init();
        AppliedPaymentEntryRecRef.GetTable(AppliedPaymentEntry);
        VerifyFieldDefinitionsDontExistInTargetTable(AppliedPaymentEntryRecRef, PaymentProposalSpecificFieldRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateFromAppliedEntry()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        NewTempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);

        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        CreateBankReconciliationLine(
          BankAccReconciliationLine, AppliedAmount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        AppliedPaymentEntry.Get(
          TempPaymentApplicationProposal."Statement Type", TempPaymentApplicationProposal."Bank Account No.",
          TempPaymentApplicationProposal."Statement No.", TempPaymentApplicationProposal."Statement Line No.",
          TempPaymentApplicationProposal."Account Type", TempPaymentApplicationProposal."Account No.",
          TempPaymentApplicationProposal."Applies-to Entry No.");

        // Execute
        NewTempPaymentApplicationProposal.CreateFromAppliedPaymentEntry(AppliedPaymentEntry);

        // Verify common fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(NewTempPaymentApplicationProposal);

        // Verify Payment Application Proposal Specific Fields
        Assert.AreEqual(
          NewTempPaymentApplicationProposal."Sorting Order", -AppliedPaymentEntry.Quality - BankPmtApplRule.GetHighestPossibleScore(),
          'Sorting order is not set correctly');
        Assert.AreEqual(
          NewTempPaymentApplicationProposal."Remaining Amount", CustLedgerEntry."Remaining Amount",
          'Remaining Amount is not set correctly');
        Assert.AreEqual(
          NewTempPaymentApplicationProposal."Remaining Amt. Incl. Discount",
          CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible",
          'Remaining Amt. Incl. Discount is not set correctly');
        Assert.AreEqual(
          NewTempPaymentApplicationProposal."Stmt To Rem. Amount Difference", 0,
          'Statement to Remaining Amount Difference is not set correctly');
        Assert.AreEqual(NewTempPaymentApplicationProposal.Applied, true, 'Applied is not set to a correct value');
        Assert.AreEqual(
          NewTempPaymentApplicationProposal."Pmt. Disc. Due Date", CustLedgerEntry."Pmt. Disc. Tolerance Date",
          'Applied is not set to a correct value');
        Assert.AreEqual(
          NewTempPaymentApplicationProposal."Remaining Pmt. Disc. Possible", CustLedgerEntry."Remaining Pmt. Disc. Possible",
          'Remaining Pmt. Disc. Possible is not set to a correct value');

        // Verify No Modifications Happened to Bank Acc Reconciliation Line
        NoOfEntries := 1;
        Difference := 0;

        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateFromMatchingBuffer()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        Amount: Decimal;
        AppliedAmount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);

        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        CreateBankReconciliationLine(
          BankAccReconciliationLine, AppliedAmount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Verify Payment Application Proposal Specific Fields
        Assert.IsTrue(
          TempPaymentApplicationProposal."Sorting Order" > -BankPmtApplRule.GetHighestPossibleScore(),
          'Sorting order is not set correctly');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Amount", CustLedgerEntry."Remaining Amount", 'Remaining Amount is not set correctly');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Amt. Incl. Discount",
          CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible",
          'Remaining Amt. Incl. Discount is not set correctly');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Stmt To Rem. Amount Difference", Amount - AppliedAmount,
          'Statement to Remaining Amount Difference is not set correctly');
        Assert.AreEqual(TempPaymentApplicationProposal.Applied, false, 'Applied is not set to a correct value');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Pmt. Disc. Due Date", CustLedgerEntry."Pmt. Disc. Tolerance Date",
          'Applied is not set to a correct value');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Pmt. Disc. Possible", CustLedgerEntry."Remaining Pmt. Disc. Possible",
          'Remaining Pmt. Disc. Possible is not set to a correct value');

        VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyTransfersEntireAmountWhenAmountsAreMatching()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', false);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Excercise
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        NoOfEntries := 1;
        Difference := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, Amount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyWhenAmountIsMissing()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', false);

        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        CreateBankReconciliationLine(
          BankAccReconciliationLine, AppliedAmount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Excercise
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        NoOfEntries := 1;
        Difference := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyWithExcessAmount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, AppliedAmount, '', false);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Excercise
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        NoOfEntries := 1;
        Difference := Amount - AppliedAmount;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyOnMultipleRecords()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TotalAmount: Decimal;
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        I: Integer;
        CustomerNo: Code[20];
    begin
        Initialize();

        NoOfEntries := 3;
        TotalAmount := 0;

        // Setup
        for I := 1 to NoOfEntries do begin
            Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
            CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, CustomerNo, false);
            CustomerNo := CustLedgerEntry."Customer No.";
            TotalAmount += Amount;
        end;

        CreateBankReconciliationLine(BankAccReconciliationLine, TotalAmount, '', '');
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        Clear(CustLedgerEntry);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetAutoCalcFields("Remaining Amount");
        CustLedgerEntry.FindSet();

        Difference := TotalAmount;

        // Excercise and verify multiple applications
        for I := 1 to NoOfEntries do begin
            TempPaymentApplicationProposal.Validate(Applied, true);
            TempPaymentApplicationProposal.Modify(true);

            Difference -= CustLedgerEntry."Remaining Amount";
            AppliedAmount += CustLedgerEntry."Remaining Amount";

            // Verify Bank Acc Reconciliation Line
            VerifyBankAccReconciliationLineIsUpdatedCorrectly(
              BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, I);

            // Verify Applied Payment Entry Exists and the fields are set
            VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

            CustLedgerEntry.Next();
            TempPaymentApplicationProposal.Next();
        end;

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUncheckingApplySingleRow()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', false);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
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
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry is removed from database
        VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
        Assert.TableIsEmpty(DATABASE::"Applied Payment Entry");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUncheckingApplyMultipleRows()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TotalAmount: Decimal;
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        I: Integer;
        CustomerNo: Code[20];
    begin
        Initialize();

        NoOfEntries := 3;
        TotalAmount := 0;

        // Setup - Apply to 3 Ledger Entries
        for I := 1 to NoOfEntries do begin
            Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
            CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, CustomerNo, false);
            CustomerNo := CustLedgerEntry."Customer No.";
            TotalAmount += Amount;
        end;

        CreateBankReconciliationLine(BankAccReconciliationLine, TotalAmount, '', '');
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        Clear(CustLedgerEntry);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetAutoCalcFields("Remaining Amount");
        CustLedgerEntry.FindSet();

        for I := 1 to NoOfEntries do begin
            TempPaymentApplicationProposal.Validate(Applied, true);
            TempPaymentApplicationProposal.Modify(true);
            CustLedgerEntry.Next();
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
              BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries - I);

            // Verify Applied Payment Entry Does not Exist and the fields are set
            VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);
            TempPaymentApplicationProposal.Next();
        end;

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
        Assert.TableIsEmpty(DATABASE::"Applied Payment Entry");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingAppliedAmountOnSingleRowAppliesEntries()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', false);

        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
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
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingAppliedAmountTooGreatRaisesError()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', false);

        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
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
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TotalAmount: Decimal;
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        I: Integer;
        CustomerNo: Code[20];
    begin
        Initialize();

        NoOfEntries := 3;
        TotalAmount := 0;

        // Setup
        for I := 1 to NoOfEntries do begin
            Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
            CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, CustomerNo, false);
            CustomerNo := CustLedgerEntry."Customer No.";
            TotalAmount += Amount;
        end;

        CreateBankReconciliationLine(BankAccReconciliationLine, TotalAmount, '', '');
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        Clear(CustLedgerEntry);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetAutoCalcFields("Remaining Amount");
        CustLedgerEntry.FindSet();

        Difference := TotalAmount;

        // Excercise and verify multiple applications
        for I := 1 to NoOfEntries do begin
            TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", CustLedgerEntry."Remaining Amount");
            TempPaymentApplicationProposal.Modify(true);

            Difference -= CustLedgerEntry."Remaining Amount";
            AppliedAmount += CustLedgerEntry."Remaining Amount";

            // Verify Applied got updated
            Assert.IsTrue(TempPaymentApplicationProposal.Applied, 'Applied should be set to True');

            // Verify Bank Acc Reconciliation Line
            VerifyBankAccReconciliationLineIsUpdatedCorrectly(
              BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, I);

            // Verify Applied Payment Entry Exists and the fields are set
            VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

            CustLedgerEntry.Next();
            TempPaymentApplicationProposal.Next();
        end;

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangingAppliedAmountUpdatesExistingEntries()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TotalAmount: Decimal;
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NewAppliedAmount: Decimal;
        NoOfEntries: Integer;
        I: Integer;
        CustomerNo: Code[20];
    begin
        Initialize();

        NoOfEntries := 3;
        TotalAmount := 0;

        // Setup
        for I := 1 to NoOfEntries do begin
            Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
            CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, CustomerNo, false);
            CustomerNo := CustLedgerEntry."Customer No.";
            TotalAmount += Amount;
        end;

        CreateBankReconciliationLine(BankAccReconciliationLine, TotalAmount, '', '');
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        Clear(CustLedgerEntry);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetAutoCalcFields("Remaining Amount");
        CustLedgerEntry.FindSet();

        Difference := TotalAmount;

        for I := 1 to NoOfEntries do begin
            TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", CustLedgerEntry."Remaining Amount");
            TempPaymentApplicationProposal.Modify(true);

            Difference -= CustLedgerEntry."Remaining Amount";
            AppliedAmount += CustLedgerEntry."Remaining Amount";

            CustLedgerEntry.Next();
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
              BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

            // Verify Applied Payment Entry Exists and the fields are updated
            VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);
            TempPaymentApplicationProposal.Next();
        end;

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingAppliedAmountToZeroUnapliesEntries()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', false);

        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        TempPaymentApplicationProposal.Validate(Applied, true);
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
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
        Assert.TableIsEmpty(DATABASE::"Applied Payment Entry");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingAppliedAmountToZeroUnappliesMultipleEntries()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TotalAmount: Decimal;
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        I: Integer;
        CustomerNo: Code[20];
    begin
        Initialize();

        NoOfEntries := 3;
        TotalAmount := 0;

        // Setup
        for I := 1 to NoOfEntries do begin
            Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
            CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, CustomerNo, false);
            CustomerNo := CustLedgerEntry."Customer No.";
            TotalAmount += Amount;
        end;

        CreateBankReconciliationLine(BankAccReconciliationLine, TotalAmount, '', '');
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        Clear(CustLedgerEntry);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetAutoCalcFields("Remaining Amount");
        CustLedgerEntry.FindSet();

        Difference := TotalAmount;

        for I := 1 to NoOfEntries do begin
            TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", CustLedgerEntry."Remaining Amount");
            TempPaymentApplicationProposal.Modify(true);

            Difference -= CustLedgerEntry."Remaining Amount";
            AppliedAmount += CustLedgerEntry."Remaining Amount";

            CustLedgerEntry.Next();
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
              BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries - I);

            // Verify Applied Payment Entry is Deleted
            VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);
            TempPaymentApplicationProposal.Next();
        end;

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
        Assert.TableIsEmpty(DATABASE::"Applied Payment Entry");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatingANewGLLine()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        GLAccount: Record "G/L Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, '', '');

        // Excercise
        CreateNewPaymentApplicationLine(
          TempPaymentApplicationProposal, BankAccReconciliationLine, TempPaymentApplicationProposal."Account Type"::"G/L Account",
          GLAccount."No.");

        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        // Verify
        Difference := 0;
        NoOfEntries := 1;
        CustLedgerEntry.Init();
        Assert.AreEqual(TempPaymentApplicationProposal."Applied Amount", Amount, 'Applied Amount was not set');
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, Amount, Difference, NoOfEntries);
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatingANewCustomerLine()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        LibrarySales.CreateCustomer(Customer);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, '', '');

        // Excercise
        CreateNewPaymentApplicationLine(
          TempPaymentApplicationProposal, BankAccReconciliationLine, TempPaymentApplicationProposal."Account Type"::Customer,
          Customer."No.");

        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        // Verify
        Difference := 0;
        NoOfEntries := 1;
        Assert.AreEqual(TempPaymentApplicationProposal."Applied Amount", Amount, 'Applied Amount was not set');

        CustLedgerEntry.Init();
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, Amount, Difference, NoOfEntries);
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatingANewVendorLine()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        Vendor: Record Vendor;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        LibraryPurchase.CreateVendor(Vendor);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, '', '');

        // Excercise
        CreateNewPaymentApplicationLine(
          TempPaymentApplicationProposal, BankAccReconciliationLine, TempPaymentApplicationProposal."Account Type"::Vendor, Vendor."No.");

        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        // Verify
        Difference := 0;
        NoOfEntries := 1;
        Assert.AreEqual(TempPaymentApplicationProposal."Applied Amount", Amount, 'Applied Amount was not set');

        CustLedgerEntry.Init();
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, Amount, Difference, NoOfEntries);
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingANewCustomerLine()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        LibrarySales.CreateCustomer(Customer);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, '', '');

        CreateNewPaymentApplicationLine(
          TempPaymentApplicationProposal, BankAccReconciliationLine, TempPaymentApplicationProposal."Account Type"::Customer,
          Customer."No.");

        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        // Excercise
        TempPaymentApplicationProposal.Delete(true);

        // Verify
        Difference := Amount;
        NoOfEntries := 0;

        CustLedgerEntry.Init();
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, Amount, Difference, NoOfEntries);
        VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
        Assert.TableIsEmpty(DATABASE::"Applied Payment Entry")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItIsNotPossibleToChangeAccountTypeWhenAmountIsApplied()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        Customer: Record Customer;
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        LibrarySales.CreateCustomer(Customer);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, '', '');

        CreateNewPaymentApplicationLine(
          TempPaymentApplicationProposal, BankAccReconciliationLine, TempPaymentApplicationProposal."Account Type"::Customer,
          Customer."No.");

        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        asserterror TempPaymentApplicationProposal.Validate("Account Type", TempPaymentApplicationProposal."Account Type"::Customer);
        Assert.ExpectedError(CannotChangeAppliedLineErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItIsNotPossibleToChangeAccountNoWhenAmountIsApplied()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        Customer: Record Customer;
        Customer2: Record Customer;
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        LibrarySales.CreateCustomer(Customer);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, '', '');
        LibrarySales.CreateCustomer(Customer2);

        CreateNewPaymentApplicationLine(
          TempPaymentApplicationProposal, BankAccReconciliationLine, TempPaymentApplicationProposal."Account Type"::Customer,
          Customer."No.");

        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        asserterror TempPaymentApplicationProposal.Validate("Account No.", Customer2."No.");
        Assert.ExpectedError(CannotChangeAppliedLineErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTransferingExcessAmountToCustomerAccount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, AppliedAmount, '', false);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        // Transfer Excess Amount to customer account
        CreateNewPaymentApplicationLine(
          TempPaymentApplicationProposal, BankAccReconciliationLine, TempPaymentApplicationProposal."Account Type"::Customer,
          CustLedgerEntry."Customer No.");

        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        Assert.AreEqual(
          TempPaymentApplicationProposal."Applied Amount", Amount - AppliedAmount,
          'Difference was not transfered correctly to customer account');
        NoOfEntries := 2;
        Difference := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, Amount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemovingOfTransferingExcessAmountToCustomerAccount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustomerTempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, AppliedAmount, '', false);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        // Transfer Excess Amount to customer account
        CreateNewPaymentApplicationLine(
          CustomerTempPaymentApplicationProposal, BankAccReconciliationLine, TempPaymentApplicationProposal."Account Type"::Customer,
          CustLedgerEntry."Customer No.");

        CustomerTempPaymentApplicationProposal.Validate(Applied, true);
        CustomerTempPaymentApplicationProposal.Modify(true);

        CustomerTempPaymentApplicationProposal.Validate(Applied, false);
        CustomerTempPaymentApplicationProposal.Modify(true);

        NoOfEntries := 1;
        Difference := Amount - AppliedAmount;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingCustomerDiscountOnNotAppliedProposal()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        NewDiscountAmount: Decimal;
        NewDiscountDueDate: Date;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, AppliedAmount, '', true);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        Assert.IsTrue(
          TempPaymentApplicationProposal."Remaining Pmt. Disc. Possible" > 0, 'Remaining Discount possible must be greater than 0');
        Assert.AreNotEqual(TempPaymentApplicationProposal."Pmt. Disc. Due Date", 0D, 'Remaining Discount possible must be greater than 0');

        NewDiscountDueDate := CalcDate('<1M>', TempPaymentApplicationProposal."Pmt. Disc. Due Date");
        NewDiscountAmount := TempPaymentApplicationProposal."Remaining Pmt. Disc. Possible" * 2;
        TempPaymentApplicationProposal.Validate("Pmt. Disc. Due Date", NewDiscountDueDate);
        TempPaymentApplicationProposal.Validate("Remaining Pmt. Disc. Possible", NewDiscountAmount);

        TempPaymentApplicationProposal.Modify(true);

        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Pmt. Disc. Possible", NewDiscountAmount, 'Discount amount was not set correctly');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Pmt. Disc. Due Date", NewDiscountDueDate, 'Discount due date was not set correctly');
        Assert.AreEqual(CustLedgerEntry."Remaining Pmt. Disc. Possible", NewDiscountAmount, 'Discount amount was not set correctly');
        Assert.AreEqual(CustLedgerEntry."Pmt. Discount Date", NewDiscountDueDate, 'Discount due date was not set correctly');

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingCustomerDiscountOnAppliedProposal()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
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
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', false);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
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

        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");

        Assert.AreEqual(CustLedgerEntry."Remaining Pmt. Disc. Possible", NewDiscountAmount, 'Discount amount was not set correctly');
        Assert.AreEqual(CustLedgerEntry."Pmt. Discount Date", NewDiscountDueDate, 'Discount due date was not set correctly');

        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, CustLedgerEntry, NewDiscountAmount, Amount);

        // Verify that customer has overpaid, difference is discount applied amount is amount without discount
        NoOfEntries := 1;
        Difference := NewDiscountAmount;
        AppliedAmount := Amount - NewDiscountAmount;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingCustomerDiscountOnAppliedProposalSettlesAmount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
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
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', false);
        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        CreateBankReconciliationLine(
          BankAccReconciliationLine, AppliedAmount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Execute
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        NewDiscountDueDate := CalcDate('<1M>', WorkDate());
        NewDiscountAmount := Amount - AppliedAmount;
        TempPaymentApplicationProposal.Validate("Pmt. Disc. Due Date", NewDiscountDueDate);
        TempPaymentApplicationProposal.Validate("Remaining Pmt. Disc. Possible", NewDiscountAmount);
        TempPaymentApplicationProposal.Modify(true);

        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");

        // Verify
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Pmt. Disc. Possible", NewDiscountAmount, 'Discount amount was not set correctly');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Pmt. Disc. Due Date", NewDiscountDueDate, 'Discount due date was not set correctly');

        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, CustLedgerEntry, NewDiscountAmount, Amount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIncreasingCustomerDiscountOnAppliedAmountTakesRemainingAmount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
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
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, AppliedAmount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Execute
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        NewDiscountDueDate := CalcDate('<1M>', WorkDate());
        NewDiscountAmount := Amount - AppliedAmount;
        TempPaymentApplicationProposal.Validate("Pmt. Disc. Due Date", NewDiscountDueDate);
        TempPaymentApplicationProposal.Validate("Remaining Pmt. Disc. Possible", NewDiscountAmount);
        TempPaymentApplicationProposal.Modify(true);

        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");

        // Verify
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Pmt. Disc. Possible", NewDiscountAmount, 'Discount amount was not set correctly');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Pmt. Disc. Due Date", NewDiscountDueDate, 'Discount due date was not set correctly');

        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, CustLedgerEntry, NewDiscountAmount, Amount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDecreasingCustomerDiscountKeepsAppliedDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
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
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Execute
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        NewDiscountDueDate := CalcDate('<1M>', WorkDate());
        NewDiscountAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        TempPaymentApplicationProposal.Validate("Pmt. Disc. Due Date", NewDiscountDueDate);
        TempPaymentApplicationProposal.Validate("Remaining Pmt. Disc. Possible", NewDiscountAmount);
        TempPaymentApplicationProposal.Modify(true);

        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");

        // Verify
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Pmt. Disc. Possible", NewDiscountAmount, 'Discount amount was not set correctly');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Pmt. Disc. Due Date", NewDiscountDueDate, 'Discount due date was not set correctly');

        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, CustLedgerEntry, NewDiscountAmount, Amount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := NewDiscountAmount;
        AppliedAmount := Amount - NewDiscountAmount;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDecreasingCustomerDiscountRemovesAppliedDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
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
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        AppliedAmount := Amount - CustLedgerEntry."Remaining Pmt. Disc. Possible";
        CreateBankReconciliationLine(
          BankAccReconciliationLine, AppliedAmount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Execute
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        NewDiscountDueDate := CalcDate('<1M>', WorkDate());
        NewDiscountAmount := Round(CustLedgerEntry."Remaining Pmt. Disc. Possible" / 2, LibraryERM.GetAmountRoundingPrecision());
        TempPaymentApplicationProposal.Validate("Pmt. Disc. Due Date", NewDiscountDueDate);
        TempPaymentApplicationProposal.Validate("Remaining Pmt. Disc. Possible", NewDiscountAmount);
        TempPaymentApplicationProposal.Modify(true);

        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");

        // Verify
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Pmt. Disc. Possible", NewDiscountAmount, 'Discount amount was not set correctly');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Pmt. Disc. Due Date", NewDiscountDueDate, 'Discount due date was not set correctly');

        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, CustLedgerEntry, 0, AppliedAmount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingAppliedAmountToZeroRemovesTheDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        AppliedAmount := Amount - CustLedgerEntry."Remaining Pmt. Disc. Possible";
        CreateBankReconciliationLine(
          BankAccReconciliationLine, AppliedAmount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Execute
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);
        TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", 0);
        TempPaymentApplicationProposal.Modify(true);

        // Verify
        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, CustLedgerEntry, 0, 0);

        // Verify No. are matching
        NoOfEntries := 0;
        Difference := AppliedAmount;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingTheFullAmountGivesTheDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Execute
        TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", Amount);
        TempPaymentApplicationProposal.Modify(true);

        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");

        // Verify
        AppliedAmount := Amount - CustLedgerEntry."Remaining Pmt. Disc. Possible";

        VerifyPaymentApplicationProposalDiscountFields(
          TempPaymentApplicationProposal, CustLedgerEntry, CustLedgerEntry."Remaining Pmt. Disc. Possible", Amount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := CustLedgerEntry."Remaining Pmt. Disc. Possible";

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingTheDiscountAmountGivesTheDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        GetAmountAndAppliedAmt(CustLedgerEntry, AppliedAmount, Amount);
        CreateCLEAndBankRecLine(CustLedgerEntry, BankAccReconciliationLine, TempPaymentApplicationProposal, Amount);
        ModifyTempPaymentAppPropsalAppliedAmt(CustLedgerEntry, TempPaymentApplicationProposal, AppliedAmount);

        // Verify
        VerifyPaymentApplicationProposalDiscountFields(
          TempPaymentApplicationProposal, CustLedgerEntry, CustLedgerEntry."Remaining Pmt. Disc. Possible", Amount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := CustLedgerEntry."Remaining Pmt. Disc. Possible";

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangingTheAmountRemovesTheDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        NewAppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        GetAmountAndAppliedAmt(CustLedgerEntry, AppliedAmount, Amount);
        CreateCLEAndBankRecLine(CustLedgerEntry, BankAccReconciliationLine, TempPaymentApplicationProposal, Amount);
        ModifyTempPaymentAppPropsalAppliedAmt(CustLedgerEntry, TempPaymentApplicationProposal, AppliedAmount);

        NewAppliedAmount := Round(AppliedAmount / 2, LibraryERM.GetAmountRoundingPrecision());

        // Execute
        TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", NewAppliedAmount);
        TempPaymentApplicationProposal.Modify(true);

        // Verify
        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, CustLedgerEntry, 0, NewAppliedAmount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := Amount - NewAppliedAmount;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, NewAppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemovingTheAmountRemovesTheDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        GetAmountAndAppliedAmt(CustLedgerEntry, AppliedAmount, Amount);
        CreateCLEAndBankRecLine(CustLedgerEntry, BankAccReconciliationLine, TempPaymentApplicationProposal, Amount);
        ModifyTempPaymentAppPropsalAppliedAmt(CustLedgerEntry, TempPaymentApplicationProposal, AppliedAmount);

        // Execute
        TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", 0);
        TempPaymentApplicationProposal.Modify(true);

        // Verify
        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, CustLedgerEntry, 0, 0);

        // Verify No. are matching
        NoOfEntries := 0;
        Difference := Amount;
        AppliedAmount := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSelectingApplySetsTheDiscountCustomerPaidFullAmount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        GetAmountAndAppliedAmt(CustLedgerEntry, AppliedAmount, Amount);
        CreateCLEAndBankRecLine(CustLedgerEntry, BankAccReconciliationLine, TempPaymentApplicationProposal, Amount);
        ModifyTempPaymentAppPropsalAppliedAmt(CustLedgerEntry, TempPaymentApplicationProposal, AppliedAmount);

        // Verify
        AppliedAmount := Amount - CustLedgerEntry."Remaining Pmt. Disc. Possible";
        VerifyPaymentApplicationProposalDiscountFields(
          TempPaymentApplicationProposal, CustLedgerEntry, CustLedgerEntry."Remaining Pmt. Disc. Possible", Amount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := CustLedgerEntry."Remaining Pmt. Disc. Possible";

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSelectingApplySetsTheDiscountCustomerPaidDiscountAmount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        GetAmountAndAppliedAmt(CustLedgerEntry, AppliedAmount, Amount);
        CreateCLEAndBankRecLine(CustLedgerEntry, BankAccReconciliationLine, TempPaymentApplicationProposal, AppliedAmount);
        ModifyTempPaymentAppPropsalApplied(CustLedgerEntry, TempPaymentApplicationProposal);

        // Verify
        VerifyPaymentApplicationProposalDiscountFields(
          TempPaymentApplicationProposal, CustLedgerEntry, CustLedgerEntry."Remaining Pmt. Disc. Possible", Amount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSelectingApplyDoesntSetDiscountIfAmountIsUnderExpectedAmount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        AppliedAmount := Round((Amount - CustLedgerEntry."Remaining Pmt. Disc. Possible") / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateBankReconciliationLine(
          BankAccReconciliationLine, AppliedAmount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Execute
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");

        // Verify
        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, CustLedgerEntry, 0, AppliedAmount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUncheckingApplyRemovesTheDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        AppliedAmount := Amount - CustLedgerEntry."Remaining Pmt. Disc. Possible";

        CreateBankReconciliationLine(
          BankAccReconciliationLine, AppliedAmount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");

        // Execute
        TempPaymentApplicationProposal.Validate(Applied, false);
        TempPaymentApplicationProposal.Modify(true);

        // Verify
        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, CustLedgerEntry, 0, 0);

        // Verify No. are matching
        NoOfEntries := 0;
        Difference := Amount;
        AppliedAmount := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyingOnMultipleLinesGivesTheDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        TempPaymentApplicationProposal2: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        Amount: Decimal;
        FirstLineAmount: Decimal;
        SecondLineAmount: Decimal;
    begin
        Initialize();

        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        FirstLineAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        SecondLineAmount := Amount - FirstLineAmount - CustLedgerEntry."Remaining Pmt. Disc. Possible";

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
          CustLedgerEntry, FirstLineAmount, SecondLineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyingOnMultipleLinesGivesTheDiscountByTypingTheAmount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        TempPaymentApplicationProposal2: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        Amount: Decimal;
        FirstLineAmount: Decimal;
        SecondLineAmount: Decimal;
    begin
        Initialize();

        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);

        PrepareTwoPaymentApplicationProposalLines(
          BankAccount, BankAccReconciliation, BankAccReconciliationLine, BankAccReconciliationLine2,
          TempPaymentApplicationProposal, TempPaymentApplicationProposal2, CustLedgerEntry, Amount, FirstLineAmount, SecondLineAmount);

        // Execute - Apply first line
        TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", FirstLineAmount);
        TempPaymentApplicationProposal.Modify(true);

        VerifyCommenDiscountSenarios(
          TempPaymentApplicationProposal, TempPaymentApplicationProposal2, BankAccReconciliationLine, BankAccReconciliationLine2,
          CustLedgerEntry, FirstLineAmount, SecondLineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotSetTheDiscountAmountToCustomerCreditLine()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, '', '');
        CreateNewPaymentApplicationLine(
          TempPaymentApplicationProposal, BankAccReconciliationLine, TempPaymentApplicationProposal."Account Type"::Customer,
          CustLedgerEntry."Customer No.");

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
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
    begin
        Initialize();

        GeneralLedgerSetup.Get();
        Evaluate(GeneralLedgerSetup."Payment Discount Grace Period", '<+10D>');
        GeneralLedgerSetup.Modify();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, '', '');
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        Assert.IsTrue(
          TempPaymentApplicationProposal."Pmt. Disc. Tolerance Date" > 0D, 'Payment Disc. Tolerance Date was not set correctly');
        Assert.AreEqual(
          CalcDate(GeneralLedgerSetup."Payment Discount Grace Period", CustLedgerEntry."Pmt. Discount Date"),
          TempPaymentApplicationProposal."Pmt. Disc. Tolerance Date", 'Payment Disc. Tolerance Date was not set correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingPaymentDiscToleranceDateDoesntChangeDueDateAndViceVersa()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
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

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, '', '');
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
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        NewTransactionDate: Date;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', false);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, '', '');
        NewTransactionDate := CalcDate('<-20D>', CustLedgerEntry."Posting Date");
        BankAccReconciliationLine.Validate("Transaction Date", NewTransactionDate);
        BankAccReconciliationLine.Modify(true);

        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        LibraryVariableStorage.Enqueue(
          StrSubstNo(TransactionDateIsBeforePostingDateTxt, NewTransactionDate, CustLedgerEntry."Posting Date"));
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        // Verify Bank Acc Reconciliation Line
        Difference := 0;
        NoOfEntries := 1;
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, Amount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure PrepareTwoPaymentApplicationProposalLines(var BankAccount: Record "Bank Account"; var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line"; var TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary; var TempPaymentApplicationProposal2: Record "Payment Application Proposal" temporary; CustLedgerEntry: Record "Cust. Ledger Entry"; Amount: Decimal; var FirstLineAmount: Decimal; var SecondLineAmount: Decimal)
    begin
        FirstLineAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        SecondLineAmount := Amount - FirstLineAmount - CustLedgerEntry."Remaining Pmt. Disc. Possible";

        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.",
          BankAccReconciliation."Statement Type"::"Payment Application");

        CreateBankReconciliationLine2(BankAccReconciliationLine, BankAccReconciliation, FirstLineAmount, '', '');
        CreateBankReconciliationLine2(BankAccReconciliationLine2, BankAccReconciliation, SecondLineAmount, '', '');
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal2, BankAccReconciliationLine2);
    end;

    local procedure VerifyCommenDiscountSenarios(var TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary; var TempPaymentApplicationProposal2: Record "Payment Application Proposal" temporary; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; FirstLineAmount: Decimal; SecondLineAmount: Decimal)
    var
        NoOfEntries: Integer;
        Difference: Decimal;
    begin
        // Verify - First line application
        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, CustLedgerEntry, 0, FirstLineAmount);

        NoOfEntries := 1;
        Difference := 0;

        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, CustLedgerEntry, FirstLineAmount, Difference, NoOfEntries);

        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");

        // Execute - Apply Second Line - ther should be a discount set
        TempPaymentApplicationProposal2.Validate(Applied, true);
        TempPaymentApplicationProposal2.Modify(true);

        // Verify - Second line application
        VerifyPaymentApplicationProposalDiscountFields(
          TempPaymentApplicationProposal2, CustLedgerEntry, CustLedgerEntry."Remaining Pmt. Disc. Possible",
          SecondLineAmount + CustLedgerEntry."Remaining Pmt. Disc. Possible");

        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine2, TempPaymentApplicationProposal2, CustLedgerEntry, SecondLineAmount, Difference, NoOfEntries);

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

    local procedure GetPaymentProposalSpecificFields(var FieldRefArray: array[10] of FieldRef)
    var
        PaymentApplicationProposal: Record "Payment Application Proposal";
        RecRef: RecordRef;
        I: Integer;
    begin
        I := 1;
        RecRef.Open(DATABASE::"Payment Application Proposal");
        PaymentApplicationProposal.Init();
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo(Applied)));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Pmt. Disc. Due Date")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Remaining Pmt. Disc. Possible")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Pmt. Disc. Tolerance Date")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Applied Amt. Incl. Discount")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Remaining Amount")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Remaining Amt. Incl. Discount")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo(Type)));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Sorting Order")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Stmt To Rem. Amount Difference")));
    end;

    local procedure AddToArray(var FieldRefArray: array[18] of FieldRef; var I: Integer; CurrFieldRef: FieldRef)
    begin
        FieldRefArray[I] := CurrFieldRef;
        I += 1;
    end;

    local procedure VerifyFieldDefinitionsMatchTableFields(RecRef: RecordRef; FieldRefArray: array[17] of FieldRef)
    var
        FieldRefTemplate: FieldRef;
        FieldRefTable: FieldRef;
        I: Integer;
    begin
        for I := 1 to ArrayLen(FieldRefArray) do begin
            FieldRefTemplate := FieldRefArray[I];
            FieldRefTable := RecRef.Field(FieldRefTemplate.Number);
            ValidateFieldDefinitionsMatch(FieldRefTable, FieldRefTemplate);
        end;
    end;

    local procedure VerifyFieldDefinitionsDontExistInTargetTable(RecRef: RecordRef; FieldRefArray: array[6] of FieldRef)
    var
        FieldRefTemplate: FieldRef;
        FieldRefTable: FieldRef;
        I: Integer;
    begin
        for I := 1 to ArrayLen(FieldRefArray) do begin
            FieldRefTemplate := FieldRefArray[I];
            asserterror FieldRefTable := RecRef.Field(FieldRefTemplate.Number);
        end;
    end;

    local procedure ValidateFieldDefinitionsMatch(FieldRef1: FieldRef; FieldRef2: FieldRef)
    begin
        Assert.AreEqual(FieldRef1.Name, FieldRef2.Name, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'names'));
        Assert.AreEqual(FieldRef1.Caption, FieldRef2.Caption, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'captions'));
        Assert.IsTrue(FieldRef1.Type = FieldRef2.Type, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'types'));
        Assert.AreEqual(FieldRef1.Length, FieldRef2.Length, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'lengths'));
        Assert.AreEqual(
          FieldRef1.OptionMembers, FieldRef2.OptionMembers, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'option string'));
        Assert.AreEqual(
          FieldRef1.OptionCaption, FieldRef2.OptionCaption, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'option caption'));
        Assert.AreEqual(FieldRef1.Relation, FieldRef2.Relation, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'table relation'));
    end;

    local procedure ErrorMessageForFieldComparison(FieldRef1: FieldRef; FieldRef2: FieldRef; MismatchType: Text): Text
    begin
        exit(
          Format(
            'Field ' +
            MismatchType +
            ' on fields ' +
            FieldRef1.Record().Name() + '.' + FieldRef1.Name + ' and ' + FieldRef2.Record().Name() + '.' + FieldRef2.Name + ' do not match.'));
    end;

    local procedure GetAmountAndAppliedAmt(var CustLedgerEntry: Record "Cust. Ledger Entry"; var AppliedAmount: Decimal; var Amount: Decimal)
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostSalesInvoiceWithOneLine(CustLedgerEntry, Amount, '', true);

        AppliedAmount := Amount - CustLedgerEntry."Remaining Pmt. Disc. Possible";
    end;

    local procedure CreateCLEAndBankRecLine(var CustLedgerEntry: Record "Cust. Ledger Entry"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary; Amount: Decimal)
    begin
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, CustLedgerEntry."Document No.", CustLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);
    end;

    local procedure ModifyTempPaymentAppPropsalAppliedAmt(var CustLedgerEntry: Record "Cust. Ledger Entry"; var TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary; AppliedAmount: Decimal)
    begin
        TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", AppliedAmount);
        TempPaymentApplicationProposal.Modify(true);

        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
    end;

    local procedure ModifyTempPaymentAppPropsalApplied(var CustLedgerEntry: Record "Cust. Ledger Entry"; var TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary)
    begin
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
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

    local procedure CreateAndPostSalesInvoiceWithOneLine(var CustLedgerEntry: Record "Cust. Ledger Entry"; Amount: Decimal; CustomerNo: Code[20]; AddDiscount: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateAndPostSalesDocWithOneLine(CustLedgerEntry, Amount, CustomerNo, AddDiscount, SalesHeader."Document Type"::Invoice);
    end;

    local procedure CreateAndPostSalesDocWithOneLine(var CustLedgerEntry: Record "Cust. Ledger Entry"; Amount: Decimal; CustomerNo: Code[20]; AddDiscount: Boolean; DocType: Enum "Gen. Journal Document Type")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PaymentTerms: Record "Payment Terms";
        DocumentNo: Code[20];
    begin
        if CustomerNo = '' then begin
            LibrarySales.CreateCustomer(Customer);
            CustomerNo := Customer."No.";

            if AddDiscount then begin
                LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
                Customer.Validate("Payment Terms Code", PaymentTerms.Code);
                Customer.Modify(true);
            end;
        end;

        CreateItem(Item, Amount);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        Clear(CustLedgerEntry);
        CustLedgerEntry.Init();
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount");
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

    local procedure VerifyBankAccReconciliationLineIsUpdatedCorrectly(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary; CustLedgerEntry: Record "Cust. Ledger Entry"; AppliedAmount: Decimal; Difference: Decimal; NoOfAppliedEntries: Integer)
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
              (StrPos(BankAccReconciliationLine.GetAppliedToDocumentNo(), CustLedgerEntry."Document No.") > 0) or
              (CustLedgerEntry."Document No." = ''), 'Document No. is not added');
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
        DummyAppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        DummyAppliedPaymentEntry.SetRange("Statement Type", TempPaymentApplicationProposal."Statement Type");
        DummyAppliedPaymentEntry.SetRange("Bank Account No.", TempPaymentApplicationProposal."Bank Account No.");
        DummyAppliedPaymentEntry.SetRange("Statement No.", TempPaymentApplicationProposal."Statement No.");
        DummyAppliedPaymentEntry.SetRange("Statement Line No.", TempPaymentApplicationProposal."Statement Line No.");
        DummyAppliedPaymentEntry.SetRange("Account Type", TempPaymentApplicationProposal."Account Type");
        DummyAppliedPaymentEntry.SetRange("Account No.", TempPaymentApplicationProposal."Account No.");
        DummyAppliedPaymentEntry.SetRange("Applies-to Entry No.", TempPaymentApplicationProposal."Applies-to Entry No.");

        Assert.RecordIsEmpty(DummyAppliedPaymentEntry);
    end;

    [Normal]
    local procedure VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary; CustLedgerEntry: Record "Cust. Ledger Entry"; ExpectedAppliedDiscountAmount: Decimal; ExpectedAppliedAmount: Decimal)
    begin
        Assert.AreEqual(
          ExpectedAppliedDiscountAmount, TempPaymentApplicationProposal."Applied Pmt. Discount",
          'Applied Pmt. Discount was not set to a correct value');
        Assert.AreEqual(ExpectedAppliedAmount, TempPaymentApplicationProposal."Applied Amount", 'Amount was not set to a correct value');
        Assert.AreEqual(
          ExpectedAppliedAmount - ExpectedAppliedDiscountAmount, TempPaymentApplicationProposal."Applied Amt. Incl. Discount",
          'Applied Amt. Including Discount was not set to correct value');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Amount", CustLedgerEntry."Remaining Amount",
          'Remaining Amount was not set to a correct value');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Amt. Incl. Discount",
          CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible",
          'Remaining Amount Incl Discount was not set to a correct value');
    end;

    [Normal]
    local procedure CloseExistingEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.ModifyAll(Open, false);

        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.ModifyAll(Open, false);
    end;

    local procedure PopulateAppliedPaymentEntry(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; var AppliedPaymentEntry: Record "Applied Payment Entry")
    var
        AccountNo: Code[20];
    begin
        // Populate Payment Application Proposal with dummy line (2 Inv and 2 CrMemo)
        AppliedPaymentEntry."Statement Type" := BankAccReconLine."Statement Type";
        AppliedPaymentEntry."Bank Account No." := BankAccReconLine."Bank Account No.";
        AppliedPaymentEntry."Statement No." := BankAccReconLine."Statement No.";
        AppliedPaymentEntry."Statement Line No." := BankAccReconLine."Statement Line No.";
        AppliedPaymentEntry."Account Type" := BankAccReconLine."Account Type";

        CreateAppliedPaymentEntry(AppliedPaymentEntry, AppliedPaymentEntry."Document Type"::"Credit Memo", AccountNo);
    end;

    local procedure CreateAppliedPaymentEntry(var AppliedPaymentEntry: Record "Applied Payment Entry"; DocType: Enum "Gen. Journal Document Type"; var AccountNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
    begin
        Amount := LibraryRandom.RandIntInRange(100, 200);
        CreateAndPostSalesDocWithOneLine(CustLedgerEntry, Amount, AccountNo, true, DocType);

        if DocType = AppliedPaymentEntry."Document Type"::"Credit Memo" then
            Amount := -Amount;

        if AccountNo = '' then
            AccountNo := CustLedgerEntry."Customer No.";

        AppliedPaymentEntry."Account No." := AccountNo;
        AppliedPaymentEntry."Applies-to Entry No." := CustLedgerEntry."Entry No.";
        AppliedPaymentEntry."Document Type" := DocType;
        AppliedPaymentEntry.Insert();
    end;

    local procedure PopulatePaymentApplicationProposal(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; var TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary)
    var
        AccountNo: Code[20];
    begin
        // Populate Payment Application Proposal with dummy line (2 Inv and 2 CrMemo)
        TempPaymentApplicationProposal."Statement Type" := BankAccReconLine."Statement Type";
        TempPaymentApplicationProposal."Bank Account No." := BankAccReconLine."Bank Account No.";
        TempPaymentApplicationProposal."Statement No." := BankAccReconLine."Statement No.";
        TempPaymentApplicationProposal."Statement Line No." := BankAccReconLine."Statement Line No.";
        TempPaymentApplicationProposal."Account Type" := BankAccReconLine."Account Type";

        CreatePaymentApplicationProposal(TempPaymentApplicationProposal, TempPaymentApplicationProposal."Document Type"::Invoice, AccountNo);
        CreatePaymentApplicationProposal(TempPaymentApplicationProposal, TempPaymentApplicationProposal."Document Type"::Invoice, AccountNo);
        CreatePaymentApplicationProposal(TempPaymentApplicationProposal, TempPaymentApplicationProposal."Document Type"::"Credit Memo", AccountNo);
        CreatePaymentApplicationProposal(TempPaymentApplicationProposal, TempPaymentApplicationProposal."Document Type"::"Credit Memo", AccountNo);
    end;

    local procedure CreatePaymentApplicationProposal(var TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary; DocType: Enum "Gen. Journal Document Type"; var AccountNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
    begin
        Amount := LibraryRandom.RandIntInRange(100, 200);
        CreateAndPostSalesDocWithOneLine(CustLedgerEntry, Amount, AccountNo, true, DocType);

        if DocType = TempPaymentApplicationProposal."Document Type"::"Credit Memo" then
            Amount := -Amount;

        if AccountNo = '' then
            AccountNo := CustLedgerEntry."Customer No.";

        TempPaymentApplicationProposal."Account No." := AccountNo;
        TempPaymentApplicationProposal."Applies-to Entry No." := CustLedgerEntry."Entry No.";
        TempPaymentApplicationProposal."Document Type" := DocType;
        TempPaymentApplicationProposal."Remaining Amount" := Amount;
        TempPaymentApplicationProposal.Insert();
    end;

    local procedure PopulateBankAccReconLine(var BankAccReconLine: Record "Bank Acc. Reconciliation Line")
    var
        BankAcc: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        BankAcc.FindFirst();

        BankAccReconciliation.Init();
        BankAccReconciliation."Statement Type" := BankAccReconLine."Statement Type"::"Payment Application";
        BankAccReconciliation."Bank Account No." := BankAcc."No.";
        BankAccReconciliation."Statement No." := Format(LibraryRandom.RandIntInRange(40, 60));
        BankAccReconciliation.Insert();

        BankAccReconLine."Statement Type" := BankAccReconciliation."Statement Type";
        BankAccReconLine."Bank Account No." := BankAccReconciliation."Bank Account No.";
        BankAccReconLine."Statement No." := BankAccReconciliation."Statement No.";
        BankAccReconLine."Statement Line No." := LibraryRandom.RandIntInRange(70, 90);

        BankAccReconLine."Account Type" := BankAccReconLine."Account Type"::Customer;
        BankAccReconLine.Difference := LibraryRandom.RandIntInRange(1000, 2000);
        BankAccReconLine."Transaction Date" := WorkDate();
        BankAccReconLine.Insert();
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

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgWantToApplyCreditMemoAndInvoices(Message: Text[1024])
    begin
        Assert.AreNotEqual(0, StrPos(Message, 'want to apply credit memos and invoices'), 'Wrong Message on Cr.Memo application')
    end;
}

