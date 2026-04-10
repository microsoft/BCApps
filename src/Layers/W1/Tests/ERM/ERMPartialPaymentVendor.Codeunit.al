codeunit 134004 "ERM Partial Payment Vendor"
{
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Application] [Purchase]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        AmountToApplyHaveSameSignError: Label '%1 must have the same sign as %2 in %3 %4=''%5''.';
        AmountToApplyLargerError: Label '%1 must not be larger than %2 in %3 %4=''%5''.';
        AmountMustNotBeEqual: Label '%1 must not be equal to %2.';
        UnknownError: Label 'Unknown Error.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyPmtToInvToAllCls()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GenJournalBatch: Record "Gen. Journal Batch";
        NoOfLines: Integer;
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
        ApplicationAmount: Decimal;
    begin
        // Test Apply Payment to Invoices so Invoices are open but Payment closed.

        // Setup: Make multiple Invoices and a Payment entry for a New Vendor from General Journal Line.
        // Calculate Invoice using RANDOM, it can be anything between .5 and 1000.
        // To close all entries take Payment Amount, multiplication of No. of Lines.
        // Create 2 to 10 Invoices Boundary 2 is important and 1 Payment Line. Post General Journal Line
        Initialize();
        NoOfLines := 2 * LibraryRandom.RandInt(5);
        InvoiceAmount := LibraryRandom.RandInt(2000) / 2;
        PaymentAmount := InvoiceAmount * NoOfLines;
        ApplicationAmount := PaymentAmount / NoOfLines;
        CreateJournalBatchWithAccount(GenJournalBatch);

        CreateDocumentLine(GenJournalLine, GenJournalBatch, NoOfLines, GenJournalLine."Document Type"::Invoice, CreateVendor(), -InvoiceAmount);
        CreateDocumentLine(
          GenJournalLine, GenJournalBatch, 1, GenJournalLine."Document Type"::Payment, GenJournalLine."Account No.", PaymentAmount);
        SaveGenJnlLineInTempTable(TempGenJournalLine, GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        // Exercise: Application equally of Payment Amount on all Invoices to close all Vendor Ledger Entries.
        ApplyLedgerEntryCreditInvoice(VendorLedgerEntry, GenJournalLine, ApplicationAmount);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);

        // Verify: Verify all Lines Remaining Amount have zero value and all entries are Closed.
        VerifyAllVendorEntriesStatus(TempGenJournalLine, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyPmtToInvToAllOpn()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GenJournalBatch: Record "Gen. Journal Batch";
        DeltaAssert: Codeunit "Delta Assert";
        NoOfLines: Integer;
        Amount: Decimal;
        ApplicationAmount: Decimal;
    begin
        // Test Apply Payment to Invoices so all Vendor entries are closed.
        // Test Apply Payments to Invoices apply to amount also on Payments that is not the applying entry.
        // Test Apply Refund to Credit Memo so all Vendor entries are open.

        // Setup: Make multiple Invoices and a Payment entry for a New Vendor from General Journal Line.
        // Calculate Invoice using RANDOM, it can be anything between .5 and 1000.
        // Application Amount can be anything between 1 and 99 % of the Payment to keep all entries are open.
        // Create 2 to 10 Invoices Boundary 2 is important and 1 Payment Line.
        // Using Delta Assert to watch Remaining Amount expected value should be change after Delta amount application.
        // Post General Journal Line.
        Initialize();
        NoOfLines := 2 * LibraryRandom.RandInt(5);
        Amount := LibraryRandom.RandInt(2000) / 2;
        ApplicationAmount := Round((Amount * LibraryRandom.RandInt(99) / 100) / NoOfLines);
        CreateJournalBatchWithAccount(GenJournalBatch);

        CreateDocumentLine(GenJournalLine, GenJournalBatch, NoOfLines, GenJournalLine."Document Type"::Invoice, CreateVendor(), -Amount);
        CreateDocumentLine(GenJournalLine, GenJournalBatch, 1, GenJournalLine."Document Type"::Payment, GenJournalLine."Account No.", Amount);
        SaveGenJnlLineInTempTable(TempGenJournalLine, GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        TempGenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Invoice);
        DeltaAssert.Init();
        CalcRmngAmtForSameDirection(DeltaAssert, TempGenJournalLine, ApplicationAmount);
        TempGenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        CalcRmngAmtForApplngEntry(DeltaAssert, TempGenJournalLine, NoOfLines, ApplicationAmount);

        // Exercise: Application Amount can be anything between 1 and 99% of the Payment Amount to keep all entries are open.
        ApplyLedgerEntryCreditInvoice(VendorLedgerEntry, GenJournalLine, ApplicationAmount);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);

        // Verify: Verify Remaining Amount using Delta Assert.
        DeltaAssert.Assert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyPmtToInvToPmtCls()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GenJournalBatch: Record "Gen. Journal Batch";
        NoOfLines: Integer;
        Amount: Decimal;
        ApplicationAmount: Decimal;
    begin
        // Test Apply Refund to Credit Memo so all Vendor entries are closed.

        // Setup: Make multiple Invoices and a Payment entry for a New Vendor from General Journal Line
        // Calculate Invoice using RANDOM, it can be anything between .5 and 1000.
        // Create 2 to 10 Invoices Boundary 2 is important and 1 Payment Line. Post General Journal Line.
        Initialize();
        NoOfLines := 2 * LibraryRandom.RandInt(5);
        Amount := LibraryRandom.RandInt(2000) / 2;
        ApplicationAmount := Amount / NoOfLines;
        CreateJournalBatchWithAccount(GenJournalBatch);

        CreateDocumentLine(GenJournalLine, GenJournalBatch, NoOfLines, GenJournalLine."Document Type"::Invoice, CreateVendor(), -Amount);
        CreateDocumentLine(GenJournalLine, GenJournalBatch, 1, GenJournalLine."Document Type"::Payment, GenJournalLine."Account No.", Amount);
        SaveGenJnlLineInTempTable(TempGenJournalLine, GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        // Exercise: Apply Payment Amount Equally on all Invoices.
        ApplyLedgerEntryCreditInvoice(VendorLedgerEntry, GenJournalLine, ApplicationAmount);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);

        // Verify: Verify Invoices are open after partial application and only Payment entry close.
        TempGenJournalLine.SetRange("Document Type", TempGenJournalLine."Document Type"::Invoice);
        VerifyAllVendorEntriesStatus(TempGenJournalLine, true);
        TempGenJournalLine.SetRange("Document Type", TempGenJournalLine."Document Type"::Payment);
        VerifyAllVendorEntriesStatus(TempGenJournalLine, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyPmtToInvAndPmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GenJournalBatch: Record "Gen. Journal Batch";
        DeltaAssert: Codeunit "Delta Assert";
        NoOfLines: Integer;
        Amount: Decimal;
        ApplicationAmount: Decimal;
    begin
        // Test Apply Refund to Credit Memo so Credit Memos are open but Refund closed.

        // Setup: Make an Invoice and multiple Payments entry for a New Vendor from General Journal Line.
        // Calculate Invoice using RANDOM, it can be anything between .5 and 1000.
        // Application can be any thing between 1 and 49 percent of Payment amount.
        // Create 2 to 10 Payments Boundary 2 is important and 1 Invoice Line. Post General Journal Line.
        // Using Delta Assert to watch Original Amount and Remaining Amount difference should zero in case of application for same entry.
        // Remaining Amount should be change only for Applying entry after Delta amount application.
        Initialize();
        NoOfLines := 2 * LibraryRandom.RandInt(5);
        Amount := LibraryRandom.RandInt(2000) / 2;
        ApplicationAmount := Round(Amount * (LibraryRandom.RandInt(49) / 100) / NoOfLines);
        CreateJournalBatchWithAccount(GenJournalBatch);

        CreateDocumentLine(GenJournalLine, GenJournalBatch, 1, GenJournalLine."Document Type"::Invoice, CreateVendor(), -Amount);
        CreateDocumentLine(
          GenJournalLine, GenJournalBatch, NoOfLines, GenJournalLine."Document Type"::Payment, GenJournalLine."Account No.", Amount);
        SaveGenJnlLineInTempTable(TempGenJournalLine, GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        TempGenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        DeltaAssert.Init();
        CalcRmngAmtForApplOnSameEntry(DeltaAssert, TempGenJournalLine);
        VendorLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");  // Filter applying entry.
        VendorLedgerEntry.FindFirst();
        DeltaAssert.AddWatch(
          DATABASE::"Vendor Ledger Entry", VendorLedgerEntry.GetPosition(), VendorLedgerEntry.FieldNo("Remaining Amount"),
          VendorLedgerEntry.Amount - ApplicationAmount);

        // Exercise: Application Amount between 1 to 49 % to Apply equally on all lines.
        ApplyLedgerEntryPaymentRefund(VendorLedgerEntry, GenJournalLine, ApplicationAmount);
        ApplyLedgerEntryCreditInvoice(VendorLedgerEntry, GenJournalLine, ApplicationAmount);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);

        // Verify: Payment Line Remaining Amount.
        DeltaAssert.Assert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyRfndToCrMemoToAllCls()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GenJournalBatch: Record "Gen. Journal Batch";
        NoOfLines: Integer;
        CrMemoAmount: Decimal;
        RefundAmount: Decimal;
        ApplicationAmount: Decimal;
    begin
        // Covers document TFS_TC_ID = 5778.

        // Setup: Make multiple Credit Memos and a Refund entry for a New Vendor from General Journal Line.
        // Calculate Credit Memo amount using RANDOM, it can be anything between .5 and 1000.
        // To close all entries take Refund Amount, multiplication of No. of Lines.
        // Create 2 to 10 Credit Memos Boundary 2 is important and 1 Refund Line. Post General Journal Line.
        Initialize();
        NoOfLines := 2 * LibraryRandom.RandInt(5);
        CrMemoAmount := LibraryRandom.RandInt(2000) / 2;
        RefundAmount := CrMemoAmount * NoOfLines;
        ApplicationAmount := RefundAmount / NoOfLines;
        CreateJournalBatchWithAccount(GenJournalBatch);

        CreateDocumentLine(
          GenJournalLine, GenJournalBatch, NoOfLines, GenJournalLine."Document Type"::"Credit Memo", CreateVendor(), CrMemoAmount);
        CreateDocumentLine(
          GenJournalLine, GenJournalBatch, 1, GenJournalLine."Document Type"::Refund, GenJournalLine."Account No.", -RefundAmount);
        SaveGenJnlLineInTempTable(TempGenJournalLine, GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        // Exercise: Application equally of Refund Amount on all Credit Memo to close all Vendor Ledger Entries
        // and Post Application Entry.
        ApplyLedgerEntryCreditInvoice(VendorLedgerEntry, GenJournalLine, -ApplicationAmount);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);

        // Verify: Verify that all Lines Remaining Amount have zero value and all entries are Closed.
        VerifyAllVendorEntriesStatus(TempGenJournalLine, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyRfndToCrMemoToAllOpn()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GenJournalBatch: Record "Gen. Journal Batch";
        DeltaAssert: Codeunit "Delta Assert";
        NoOfLines: Integer;
        Amount: Decimal;
        ApplicationAmount: Decimal;
    begin
        // Covers documents TFS_TC_ID = 5777, 5779 and 5781.

        // Setup: Make multiple Credit Memos and a Refund entry for a New Vendor from General Journal Line.
        // Calculate Credit Memo amount using RANDOM, it can be anything between .5 and 1000.
        // Application Amount can be anything between 1 and 99 % of the Refund to keep all entries are open.
        // Create 2 to 10 Credit Memos Boundary 2 is important and 1 Refund Line.
        // Using Delta Assert to watch Remaining Amount expected value should be change after Delta amount application.
        // Post General Journal Line.
        Initialize();
        NoOfLines := 2 * LibraryRandom.RandInt(5);
        Amount := LibraryRandom.RandInt(2000) / 2;
        ApplicationAmount := Round((Amount * LibraryRandom.RandInt(99) / 100) / NoOfLines);
        CreateJournalBatchWithAccount(GenJournalBatch);

        CreateDocumentLine(GenJournalLine, GenJournalBatch, NoOfLines, GenJournalLine."Document Type"::"Credit Memo", CreateVendor(), Amount);
        CreateDocumentLine(GenJournalLine, GenJournalBatch, 1, GenJournalLine."Document Type"::Refund, GenJournalLine."Account No.", -Amount);
        SaveGenJnlLineInTempTable(TempGenJournalLine, GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        TempGenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::"Credit Memo");
        DeltaAssert.Init();
        CalcRmngAmtForSameDirection(DeltaAssert, TempGenJournalLine, -ApplicationAmount);
        TempGenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Refund);
        CalcRmngAmtForApplngEntry(DeltaAssert, TempGenJournalLine, NoOfLines, -ApplicationAmount);

        // Exercise: Application Amount can be anything between 1 and 99% of the Refund Amount to keep all entries are open.
        // Apply partial Refund on all Credit Memos from Vendor Ledger Entry and Post Application Entry.
        ApplyLedgerEntryCreditInvoice(VendorLedgerEntry, GenJournalLine, -ApplicationAmount);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);

        // Verify: Verify Remaining Amount for all entries.
        DeltaAssert.Assert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyRfndToCrMemoToRfndCls()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GenJournalBatch: Record "Gen. Journal Batch";
        NoOfLines: Integer;
        Amount: Decimal;
        ApplicationAmount: Decimal;
    begin
        // Covers documents TFS_TC_ID=5977, TFS_TC_ID = 5780.

        // Setup: Make multiple Credit Memos and a Refund entry for a New Vendor from General Journal Line.
        // Calculate Credit Memo amount using RANDOM, it can be anything between .5 and 1000.
        // Create 2 to 10 Credit Memos Boundary 2 is important and 1 Refund Line. Post General Journal Line.
        Initialize();
        NoOfLines := 2 * LibraryRandom.RandInt(5);
        Amount := LibraryRandom.RandInt(2000) / 2;
        ApplicationAmount := Amount / NoOfLines;
        CreateJournalBatchWithAccount(GenJournalBatch);

        CreateDocumentLine(GenJournalLine, GenJournalBatch, NoOfLines, GenJournalLine."Document Type"::"Credit Memo", CreateVendor(), Amount);
        CreateDocumentLine(GenJournalLine, GenJournalBatch, 1, GenJournalLine."Document Type"::Refund, GenJournalLine."Account No.", -Amount);
        SaveGenJnlLineInTempTable(TempGenJournalLine, GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        // Exercise: Apply Refund Amount Equally on all Credit Memos to close Refund entry from Vendor Ledger Entry
        // and Post Application Entry.
        ApplyLedgerEntryCreditInvoice(VendorLedgerEntry, GenJournalLine, -ApplicationAmount);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);

        // Verify: Verify Credit Memos are open after partial application and only Refund entry close.
        TempGenJournalLine.SetRange("Document Type", TempGenJournalLine."Document Type"::Refund);
        VerifyAllVendorEntriesStatus(TempGenJournalLine, false);

        TempGenJournalLine.SetRange("Document Type", TempGenJournalLine."Document Type"::"Credit Memo");
        VerifyAllVendorEntriesStatus(TempGenJournalLine, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyRfndToCrMemoAndRfnd()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GenJournalBatch: Record "Gen. Journal Batch";
        DeltaAssert: Codeunit "Delta Assert";
        NoOfLines: Integer;
        Amount: Decimal;
        ApplicationAmount: Decimal;
    begin
        // Covers documents TFS_TC_ID=5977, TFS_TC_ID = 5782.

        // Setup: Make a Credit Memo and multiple Refunds entry for half of Credit Memo value for a New Vendor from General Journal Line.
        // Calculate Credit Memo amount using RANDOM, it can be anything between .5 and 1000.
        // Application can be any thing between 1 and 49 percent of Refund amount.
        // Create 2 to 10 Refund Boundary 2 is important and 1 Credit Memo Line.
        // Using Delta Assert to watch Original Amount and Remaining Amount difference should be zero in case of application for same entry.
        // Using Delta Assert to watch Remaining Amount should be change only for Applying entry after Delta amount application.
        // Post General Journal Line.

        Initialize();
        NoOfLines := 2 * LibraryRandom.RandInt(5);
        Amount := LibraryRandom.RandInt(2000) / 2;
        ApplicationAmount := Round(Amount * (LibraryRandom.RandInt(49) / 100) / NoOfLines);
        CreateJournalBatchWithAccount(GenJournalBatch);

        CreateDocumentLine(GenJournalLine, GenJournalBatch, 1, GenJournalLine."Document Type"::"Credit Memo", CreateVendor(), Amount);
        CreateDocumentLine(
          GenJournalLine, GenJournalBatch, NoOfLines, GenJournalLine."Document Type"::Refund, GenJournalLine."Account No.", -Amount);
        SaveGenJnlLineInTempTable(TempGenJournalLine, GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        TempGenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Refund);
        DeltaAssert.Init();
        CalcRmngAmtForApplOnSameEntry(DeltaAssert, TempGenJournalLine);
        VendorLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");  // Filter applying entry.
        VendorLedgerEntry.FindFirst();
        DeltaAssert.AddWatch(
          DATABASE::"Vendor Ledger Entry", VendorLedgerEntry.GetPosition(), VendorLedgerEntry.FieldNo("Remaining Amount"),
          VendorLedgerEntry.Amount + ApplicationAmount);

        // Exercise: Application Amount between 1 to 49 % to Apply equally on all lines.
        ApplyLedgerEntryPaymentRefund(VendorLedgerEntry, GenJournalLine, -ApplicationAmount);
        ApplyLedgerEntryCreditInvoice(VendorLedgerEntry, GenJournalLine, -ApplicationAmount);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);

        // Verify: Refund Line Remaining Amount.
        DeltaAssert.Assert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentBySetAppliesToID()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test partial application of Payment to Invoice by using Set Applies-to ID .

        ApplicationBySetAppliesToID(VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundBySetAppliesToID()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test partial application of Refund to Credit Memo by using Set Applies-to ID .

        ApplicationBySetAppliesToID(VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund);
    end;

    local procedure ApplicationBySetAppliesToID(VendorLedgerEntryDocumentType: Enum "Gen. Journal Document Type"; GeneralJournalLineDocumentType: Enum "Gen. Journal Document Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        // 1. Setup: Create a new Vendor with Payment Terms, new Gen. Journal Batch and Gen. Journal Template.
        // Create a new G/L Account and random number of Gen. Journal Lines of type Invoice and Credit Memo and post them.
        // Create a Gen. Journal Line of type Payment/Refund as per parameter passed with random partial Amount.
        Initialize();
        CreatePostGeneralJournalLines(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo");

        FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntryDocumentType);
        Amount := Round(VendorLedgerEntry."Remaining Amount" / (1 + LibraryRandom.RandInt(10)));
        CreateLineWhichWillBeApplied(GenJournalLine, GeneralJournalLineDocumentType, Amount);

        // 2. Exercise: Apply Payment/Refund to Invoice/Credit Memo and post Payment/Refund line.
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
        SetAppliesToIDInGenJournalLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        // 3. Verify: Verify Remaining Amount in Vendor Ledger Entry.
        VendorLedgerEntry.FindFirst();
        VerifyRemainingAmountInLedger(VendorLedgerEntry, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyMoreThanPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test partial application of Payment to Invoice where Amount to Apply is more than Payment Amount.

        ApplyWhereAmountToApplyIsMore(VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyMoreThanRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test partial application of Refund to Credit Memo where Amount to Apply is more than Refund Amount.

        ApplyWhereAmountToApplyIsMore(VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund);
    end;

    local procedure ApplyWhereAmountToApplyIsMore(VendorLedgerEntryDocumentType: Enum "Gen. Journal Document Type"; GeneralJournalLineDocumentType: Enum "Gen. Journal Document Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        // Test partial application of Refund to Credit Memo where Amount to Apply is more than Refund Amount.

        // 1. Setup: Create a new Vendor with Payment Terms, new Gen. Journal Batch and Gen. Journal Template.
        // Create a new G/L Account and random number of Gen. Journal Lines of type Invoice and Credit Memo and post them.
        // Create a Gen. Journal Line of type Payment/Refund as per parameter passed with random partial Amount.
        Initialize();
        CreatePostGeneralJournalLines(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo");

        FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntryDocumentType);
        Amount := Round(VendorLedgerEntry."Remaining Amount" / (1 + LibraryRandom.RandInt(10)));
        CreateLineWhichWillBeApplied(GenJournalLine, GeneralJournalLineDocumentType, Amount);

        // 2. Exercise: Apply Payment/Refund to Invoice/Credit Memo and post Payment/Refund line.
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, -GenJournalLine.Amount);
        SetAppliesToIDInGenJournalLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        // 3. Verify: Verify Remaining Amount in Vendor Ledger Entry.
        VendorLedgerEntry.FindFirst();
        VerifyRemainingAmountInLedger(VendorLedgerEntry, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyLessThanPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test partial application of Payment to Invoice where Amount to Apply is less than Payment Amount.

        ApplyWhereAmountToApplyIsLess(
          VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyLessThanRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test partial application of Refund to Credit Memo where Amount to Apply is less than Refund Amount.

        ApplyWhereAmountToApplyIsLess(
          VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyLessThanInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test partial application of Invoice to Payment where Amount to Apply is less than Invoice Amount.

        ApplyWhereAmountToApplyIsLess(
          VendorLedgerEntry."Document Type"::Payment,
          GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyLessThanMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test partial application of Credit Memo to Refund where Amount to Apply is less than Credit Memo Amount.

        ApplyWhereAmountToApplyIsLess(
          VendorLedgerEntry."Document Type"::Refund,
          GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::"Credit Memo");
    end;

    local procedure ApplyWhereAmountToApplyIsLess(VendorLedgerEntryDocumentType: Enum "Gen. Journal Document Type"; SetupGeneralLineDocumentType: Enum "Gen. Journal Document Type"; SetupGeneralLineDocumentType2: Enum "Gen. Journal Document Type"; GeneralJournalLineDocumentType: Enum "Gen. Journal Document Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        // 1. Setup: Create a new Vendor with Payment Terms, new Gen. Journal Batch and Gen. Journal Template.
        // Create a new G/L Account and random number of Gen. Journal Lines of type Invoice and Credit Memo and post them.
        // Create a Gen. Journal Line of type Payment/Refund as per parameter passed with random partial Amount.
        Initialize();
        CreatePostGeneralJournalLines(GenJournalLine, SetupGeneralLineDocumentType, SetupGeneralLineDocumentType2);

        FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntryDocumentType);
        Amount := Round(VendorLedgerEntry."Remaining Amount" * LibraryRandom.RandInt(10));
        CreateLineWhichWillBeApplied(GenJournalLine, GeneralJournalLineDocumentType, Amount);

        // 2. Exercise: Apply Payment/Refund to Invoice/Credit Memo and post Payment/Refund line.
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Remaining Amount");
        SetAppliesToIDInGenJournalLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        // 3. Verify: Verify Remaining Amount in Vendor Ledger Entry.
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount);
        VerifyRemainingAmountInLedger(VendorLedgerEntry, VendorLedgerEntry.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyByChangingAppliesToFields()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AmountApplied: Decimal;
    begin
        // Test partial application of Payment to Invoice by changing Amount to Apply, Applies-to Doc. Type
        // and Applies-to Doc. No.

        // 1. Setup: Create a new Vendor with Payment Terms, new Gen. Journal Batch and Gen. Journal Template.
        // Create a new G/L Account and random number of Gen. Journal Lines of type Invoice and Credit Memo and post them.
        // Create a Gen. Journal Line of type Payment with random partial Amount.
        Initialize();
        CreatePostGeneralJournalLines(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo");

        FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntry."Document Type"::Invoice);
        AmountApplied := Round(VendorLedgerEntry."Remaining Amount" / (1 + LibraryRandom.RandInt(10)));
        CreateLineWhichWillBeApplied(GenJournalLine, GenJournalLine."Document Type"::Payment, AmountApplied);

        // 2. Exercise: Apply Payment to Invoice by changing Applies-to Doc. Type, Applies-to Doc. No. and post Payment line.
        AppliesDocumentGenJournalLine(GenJournalLine, VendorLedgerEntry."Document No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        // 3. Verify: Verify Remaining Amount in Vendor Ledger Entry.
        VerifyRemainingAmountInLedger(VendorLedgerEntry, AmountApplied);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplySameSignError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test that the application generates an error on application of Payment to Invoice
        // where Amount to Apply has different sign than the Remaining Amount in Vendor Ledger Entry.

        AmountToApplyHasSameSignError(VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplySameSignRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test that the application generates an error on application of Refund to Credit Memo
        // where Amount to Apply has different sign than the Remaining Amount in Vendor Ledger Entry.

        AmountToApplyHasSameSignError(VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund);
    end;

    local procedure AmountToApplyHasSameSignError(VendorLedgerEntryDocumentType: Enum "Gen. Journal Document Type"; GeneralJournalLineDocumentType: Enum "Gen. Journal Document Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        // 1. Setup: Create a new Vendor with Payment Terms, new Gen. Journal Batch and Gen. Journal Template.
        // Create a new G/L Account and random number of Gen. Journal Lines of type Invoice and Credit Memo and post them.
        // Create a Gen. Journal Line of type Payment/Refund as per parameter passed with random partial Amount.
        Initialize();
        CreatePostGeneralJournalLines(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo");

        FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntryDocumentType);
        Amount := Round(VendorLedgerEntry."Remaining Amount" / (1 + LibraryRandom.RandInt(10)));
        CreateLineWhichWillBeApplied(GenJournalLine, GeneralJournalLineDocumentType, Amount);

        // 2. Exercise: Try to set Amount to Apply having different sign than Remaining Amount.
        Commit();  // Commit is required to match errors.
        asserterror LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, GenJournalLine.Amount);

        // 3. Verify: Verify that the application generates an error on application of Payment/Refund To Invoice/Credit Memo
        // where Amount to Apply has different sign than the Remaining Amount in Vendor Ledger Entry.
        VerifyAmountSameSignError(VendorLedgerEntry."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyMoreThanInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test that the application generates an error on application of Payment to Invoice
        // where Amount to Apply is more than the Invoice Amount.

        AmountToApplyMoreThanInitial(VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, 1)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyMoreThanCredit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test that the application generates an error on application of Refund to Credit Memo
        // where Amount to Apply is more than the Credit Memo Amount.

        AmountToApplyMoreThanInitial(VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -1)
    end;

    local procedure AmountToApplyMoreThanInitial(VendorLedgerEntryDocumentType: Enum "Gen. Journal Document Type"; GeneralJournalLineDocumentType: Enum "Gen. Journal Document Type"; SignFactor: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        // 1. Setup: Create a new Vendor with Payment Terms, new Gen. Journal Batch and Gen. Journal Template.
        // Create a new G/L Account and random number of Gen. Journal Lines of type Invoice and Credit Memo and post them.
        // Create a Gen. Journal Line of type Payment/Refund as per parameter passed with random partial Amount.
        Initialize();
        CreatePostGeneralJournalLines(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo");

        FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntryDocumentType);
        Amount := Round(VendorLedgerEntry."Remaining Amount" / (1 + LibraryRandom.RandInt(10)));
        CreateLineWhichWillBeApplied(GenJournalLine, GeneralJournalLineDocumentType, SignFactor * Amount);

        // 2. Exercise: Try to set Amount to Apply more than Invoice/Credit Memo Amount.
        Commit();  // Commit is required to match errors.
        asserterror LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry.Amount * (1 + LibraryRandom.RandInt(10)));

        // 3. Verify: Verify that the application generates an error on application of Payment/Refund To Invoice/Credit Memo
        // where Amount to Apply has different sign than the Remaining Amount in Vendor Ledger Entry.
        VerifyAmountLargerError(VendorLedgerEntry."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplytoOldestByPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test Apply to Oldest Functionality for Vendor with Document Type Payment.

        ApplytoOldestWithInvoice(GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplytoOldestByCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test Apply to Oldest Functionality for Vendor with Document Type Credit Memo.

        ApplytoOldestWithInvoice(GenJournalLine."Document Type"::"Credit Memo");
    end;

    local procedure ApplytoOldestWithInvoice(DocumentType: Enum "Gen. Journal Document Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
        Counter: Integer;
        VendorNo: Code[20];
    begin
        // 1. Setup: Create and Post Multiple Purchase Invoices.
        Initialize();
        VendorNo := CreateVendorWithApplyToOldest();
        for Counter := 1 to 1 + LibraryRandom.RandInt(5) do
            // Using RANDOM value for Amount.
            CreateAndPostGeneralLine(
              GenJournalLine, VendorNo, -LibraryRandom.RandDec(100, 2), GenJournalLine."Document Type"::Invoice);

        // 2. Exercise: Post Payment for Vendor.
        // Added 100 in Value so that payment value must be greater that Invoice.
        CreateAndPostGeneralLine(GenJournalLine, VendorNo, 100 + LibraryRandom.RandDec(50, 2), DocumentType);

        // 3. Verify: Verify that Payment Applies to Oldest Invoice.
        VerifyVendorLedgerEntry(VendorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorAsBalanceAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        // Test Vendor As Balance Account and Apply.

        // 1. Setup: Create Vendor, General Journal Line and Post.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGeneralLine(
          GenJournalLine, Vendor."No.", -LibraryRandom.RandDec(100, 2), GenJournalLine."Document Type"::Invoice);

        // 2. Exercise: Post Payment for Vendor as Balance Account.
        CreateAndPostPayment(GenJournalLine, Vendor."No.", GenJournalLine."Document No.", GenJournalLine.Amount);

        // 3. Verify: Verify that Payment Applies to Invoice.
        VerifyVendorLedgerEntry(Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentToInvoiceCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test application of Payment to Invoice with Currency.

        ApplyWithMoreCurrency(
          VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundToMemoCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test application of Refund to Credit Memo with Currency.

        ApplyWithMoreCurrency(
          VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund);
    end;

    local procedure ApplyWithMoreCurrency(VendorLedgerEntryDocumentType: Enum "Gen. Journal Document Type"; SetupGeneralLineDocumentType: Enum "Gen. Journal Document Type"; SetupGeneralLineDocumentType2: Enum "Gen. Journal Document Type"; GeneralJournalLineDocumentType: Enum "Gen. Journal Document Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AmountRoundingPrecision: Decimal;
    begin
        // 1. Setup: Create a new Vendor with Payment Terms, new Gen. Journal Batch and Gen. Journal Template.
        // Create a new G/L Account and random number of Gen. Journal Lines of type Invoice and Credit Memo and post them.
        // Create a Gen. Journal Line of type Payment/Refund as per parameter passed with random partial Amount.
        Initialize();
        CreatePostGeneralJournalLines(GenJournalLine, SetupGeneralLineDocumentType, SetupGeneralLineDocumentType2);

        FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntryDocumentType);
        CreateLineWhichWillBeApplied(GenJournalLine, GeneralJournalLineDocumentType, VendorLedgerEntry."Remaining Amount");

        // 2. Exercise: Apply Payment/Refund to Invoice/Credit Memo, input Currency with random greater Exchange Rate
        // and post Payment/Refund line.
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Remaining Amount");
        SetAppliesToIDInGenJournalLine(GenJournalLine);
        InputCurrencyInGenJournalLine(
          GenJournalLine, CreateCurrencyWithExchange(AmountRoundingPrecision, LibraryRandom.RandInt(100)));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        // 3. Verify: Verify Remaining Amount in Vendor Ledger Entry.
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount);
        VerifyRemainingAmountInLedger(VendorLedgerEntry, VendorLedgerEntry.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentLessCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test application of Payment to Invoice with Currency.

        ApplyWithLessCurrency(
          VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundLessCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test application of Refund to Credit Memo with Currency.

        ApplyWithLessCurrency(
          VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund);
    end;

    local procedure ApplyWithLessCurrency(VendorLedgerEntryDocumentType: Enum "Gen. Journal Document Type"; SetupGeneralLineDocumentType: Enum "Gen. Journal Document Type"; SetupGeneralLineDocumentType2: Enum "Gen. Journal Document Type"; GeneralJournalLineDocumentType: Enum "Gen. Journal Document Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AmountRoundingPrecision: Decimal;
    begin
        // 1. Setup: Create a new Vendor with Payment Terms, new Gen. Journal Batch with new G/L Account.
        // Create a random number of Gen. Journal Lines of type Invoice and Credit Memo and post them.
        // Create a Gen. Journal Line of type Payment/Refund as per parameter passed with random partial Amount.
        Initialize();
        CreatePostGeneralJournalLines(GenJournalLine, SetupGeneralLineDocumentType, SetupGeneralLineDocumentType2);

        FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntryDocumentType);
        CreateLineWhichWillBeApplied(GenJournalLine, GeneralJournalLineDocumentType, VendorLedgerEntry."Remaining Amount");

        // 2. Exercise: Apply Payment/Refund to Invoice/Credit Memo, input Currency with random lesser Exchange Rate
        // and post Payment/Refund line.
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Remaining Amount");
        SetAppliesToIDInGenJournalLine(GenJournalLine);
        InputCurrencyInGenJournalLine(
          GenJournalLine, CreateCurrencyWithExchange(AmountRoundingPrecision, LibraryUtility.GenerateRandomFraction()));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        // 3. Verify: Verify Remaining Amount in Vendor Ledger Entry.
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount);
        VerifyRemainingAmountInLedger(
          VendorLedgerEntry, Round(VendorLedgerEntry.Amount / GenJournalLine."Currency Factor", AmountRoundingPrecision));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentToMultipleDocument()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test partial application of Payment to Invoice for multiple Invoice lines.

        ApplyForMultipleDocuments(
          VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundToMultipleDocument()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test partial application of Refund to Credit Memo for multiple Credit Memo lines.

        ApplyForMultipleDocuments(
          VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund);
    end;

    local procedure ApplyForMultipleDocuments(VendorLedgerEntryDocumentType: Enum "Gen. Journal Document Type"; SetupGeneralLineDocumentType: Enum "Gen. Journal Document Type"; SetupGeneralLineDocumentType2: Enum "Gen. Journal Document Type"; GeneralJournalLineDocumentType: Enum "Gen. Journal Document Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        // 1. Setup: Create a new Vendor with Payment Terms, new Gen. Journal Batch.
        // Create a new G/L Account and random number of Gen. Journal Lines of type Invoice and Credit Memo and post them.
        // Create a Gen. Journal Line of type Payment/Refund as per parameter passed with random partial Amount.
        Initialize();
        CreatePostGeneralJournalLines(GenJournalLine, SetupGeneralLineDocumentType, SetupGeneralLineDocumentType2);

        Amount :=
          Round(
            FindVendorLedgerEntriesAmount(VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntryDocumentType) *
            LibraryRandom.RandInt(10));
        CreateLineWhichWillBeApplied(GenJournalLine, GeneralJournalLineDocumentType, Amount);

        // 2. Exercise: Apply Payment/Refund to all lines of Invoice/Credit Memo and post Payment/Refund line.
        SetApplyVendorEntry(VendorLedgerEntry);
        SetAppliesToIDInGenJournalLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        // 3. Verify: Verify Remaining Amount is 0 in all Vendor Ledger Entry of Type Invoice/Credit Memo.
        VerifyRemainingAmountInEntries(VendorLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceGreaterThanTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test Tolerance in Vendor Ledger Entry for Payment where Amount exceeds Tolerance limit.

        AmountExceedsPaymentTolerance(
          VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document Type"::Invoice, -1); // Signfactor is -1.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoGreaterThanTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test Tolerance in Vendor Ledger Entry for Credit Memo where Amount exceeds Tolerance limit.

        AmountExceedsPaymentTolerance(
          VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document Type"::"Credit Memo", 1); // Signfactor is 1.
    end;

    local procedure AmountExceedsPaymentTolerance(VendorLedgerEntryDocumentType: Enum "Gen. Journal Document Type"; SetupGeneralLineDocumentType: Enum "Gen. Journal Document Type"; SignFactor: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        GenJournalBatch: Record "Gen. Journal Batch";
        Currency: Record Currency;
        AmountRoundingPrecision: Decimal;
        CurrencyCode: Code[10];
    begin
        // 1. Setup: Create a new Currency with Exchange Rate. Create a new Vendor with Payment Terms having Discount and change Payment
        // Tolerance on Currency. Create a new Gen. Journal Batch with G/L Account.
        Initialize();
        CurrencyCode := CreateCurrencyWithExchange(AmountRoundingPrecision, LibraryUtility.GenerateRandomFraction());
        CreatePaymentTermsWithDiscount(PaymentTerms);
        ChangePaymentToleranceCurrency(CurrencyCode);
        Currency.Get(CurrencyCode);
        CreateJournalBatchWithAccount(GenJournalBatch);

        // 2. Exercise: Create a new Gen. Journal Line of type Invoice/Credit Memo with Currency as per parameter passed,
        // where Amount exceeds Tolerance limit and post it.
        CreateDocumentLine(
          GenJournalLine, GenJournalBatch, 1, SetupGeneralLineDocumentType, CreateVendorWithPaymentTerms(PaymentTerms.Code),
          SignFactor * Currency."Max. Payment Tolerance Amount" / Currency."Payment Tolerance %" * 1000);
        InputCurrencyInGenJournalLine(GenJournalLine, CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        // 3. Verify: Check the Max. Payment Tolerance and Payment Discounts in Vendor Ledger Entry.
        FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntryDocumentType);
        VendorLedgerEntry.TestField("Max. Payment Tolerance", SignFactor * Currency."Max. Payment Tolerance Amount");
        VendorLedgerEntry.TestField("Original Pmt. Disc. Possible", Round(GenJournalLine.Amount * PaymentTerms."Discount %" / 100));
        VendorLedgerEntry.TestField("Remaining Pmt. Disc. Possible", Round(GenJournalLine.Amount * PaymentTerms."Discount %" / 100));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceLessThanTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test Tolerance in Vendor Ledger Entry for Payment where Amount is less than Tolerance limit.

        AmountLessThanPaymentTolerance(
          VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document Type"::Invoice, -1); // Signfactor is -1.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoLessThanTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test Tolerance in Vendor Ledger Entry for Credit Memo where Amount is less than Tolerance limit.

        AmountLessThanPaymentTolerance(
          VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document Type"::"Credit Memo", 1); // Sign Factor is 1.
    end;

    local procedure AmountLessThanPaymentTolerance(VendorLedgerEntryDocumentType: Enum "Gen. Journal Document Type"; SetupGeneralLineDocumentType: Enum "Gen. Journal Document Type"; SignFactor: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        GenJournalBatch: Record "Gen. Journal Batch";
        Currency: Record Currency;
        AmountRoundingPrecision: Decimal;
        CurrencyCode: Code[10];
    begin
        // 1. Setup: Create a new Vendor with Payment Terms having Discount. Create a new Currency and setup Tolerance on it.
        // Create a new Gen. Journal Batch with G/L Account.
        Initialize();
        CurrencyCode := CreateCurrencyWithExchange(AmountRoundingPrecision, LibraryUtility.GenerateRandomFraction());
        CreatePaymentTermsWithDiscount(PaymentTerms);
        ChangePaymentToleranceCurrency(CurrencyCode);
        Currency.Get(CurrencyCode);
        CreateJournalBatchWithAccount(GenJournalBatch);

        // 2. Exercise: Create a new Gen. Journal Line of type Invoice/Credit Memo with Currency as per parameter passed,
        // where Amount is less than Tolerance limit and post it.
        CreateDocumentLine(
          GenJournalLine, GenJournalBatch, 1, SetupGeneralLineDocumentType, CreateVendorWithPaymentTerms(PaymentTerms.Code),
          SignFactor * Currency."Max. Payment Tolerance Amount" / Currency."Payment Tolerance %" / 2);
        InputCurrencyInGenJournalLine(GenJournalLine, CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        // 3. Verify: Check the Max. Payment Tolerance and Payment Discount Amounts in Vendor Ledger Entry.
        FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntryDocumentType);
        VendorLedgerEntry.TestField(
          "Max. Payment Tolerance",
          Round(Currency."Payment Tolerance %" * VendorLedgerEntry.Amount / 100, Currency."Amount Rounding Precision"));
        VendorLedgerEntry.TestField("Original Pmt. Disc. Possible", Round(GenJournalLine.Amount * PaymentTerms."Discount %" / 100));
        VendorLedgerEntry.TestField("Remaining Pmt. Disc. Possible", Round(GenJournalLine.Amount * PaymentTerms."Discount %" / 100));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplyInvoiceMoreTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test Tolerance in Detailed Vendor Ledger Entry for Payment where Amount exceeds Tolerance limit.

        ApplyExceedsPaymentTolerance(
          VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::Payment, VendorLedgerEntry."Document Type"::Payment, -1); // Signfactor is -1.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplyCreditMemoMoreTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test Tolerance in Detailed Vendor Ledger Entry for Credit Memo where Amount exceeds Tolerance limit.

        ApplyExceedsPaymentTolerance(
          VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Refund, VendorLedgerEntry."Document Type"::Refund, 1); // Signfactor is 1.
    end;

    local procedure ApplyExceedsPaymentTolerance(VendorLedgerEntryDocumentType: Enum "Gen. Journal Document Type"; SetupGeneralLineDocumentType: Enum "Gen. Journal Document Type"; GeneralJournalLineDocumentType: Enum "Gen. Journal Document Type"; AppliedVendorEntryDocumentType: Enum "Gen. Journal Document Type"; SignFactor: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        GenJournalBatch: Record "Gen. Journal Batch";
        Currency: Record Currency;
        Amount: Decimal;
        AmountRoundingPrecision: Decimal;
        DiscountAmount: Decimal;
        CurrencyCode: Code[10];
    begin
        // 1. Setup: Create a new Vendor with Payment Terms having Discount and change Payment Tolerance in Currency.
        // Create a new Gen. Journal Batch with G/L Account and Gen. Journal Line of type Invoice/Credit Memo with Currency as
        // per parameter passed and post it. Create Gen. Journal Line of type Payment/Refund with Currency, where Amount exceeds
        // Tolerance limit.
        Initialize();
        CurrencyCode := CreateCurrencyWithExchange(AmountRoundingPrecision, LibraryUtility.GenerateRandomFraction());
        CreatePaymentTermsWithDiscount(PaymentTerms);
        ChangePaymentToleranceCurrency(CurrencyCode);
        Currency.Get(CurrencyCode);
        CreateJournalBatchWithAccount(GenJournalBatch);

        CreateDocumentLine(
          GenJournalLine, GenJournalBatch, 1, SetupGeneralLineDocumentType, CreateVendorWithPaymentTerms(PaymentTerms.Code),
          SignFactor * Currency."Max. Payment Tolerance Amount" / Currency."Payment Tolerance %" * 1000);
        InputCurrencyInGenJournalLine(GenJournalLine, CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntryDocumentType);

        DiscountAmount := Round(Abs(GenJournalLine.Amount) * PaymentTerms."Discount %" / 100);
        Amount :=
          SignFactor * (Abs(GenJournalLine.Amount) - DiscountAmount - Abs(Currency."Max. Payment Tolerance Amount"));
        CreateLineWhichWillBeApplied(GenJournalLine, GeneralJournalLineDocumentType, Amount);
        InputCurrencyInGenJournalLine(GenJournalLine, CurrencyCode);
        ChangePostingDateInJournalLine(GenJournalLine, VendorLedgerEntry."Pmt. Disc. Tolerance Date");

        // 2. Exercise: Apply Payment/Refund to Invoice/Credit Memo and post Payment/Refund line.
        ApplyVendorLedgerWithTolerance(VendorLedgerEntry, Amount, SignFactor * Currency."Max. Payment Tolerance Amount");
        SetAppliesToIDInGenJournalLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.

        // 3. Verify: Verify the Amount in Payment Tolerance and Payment Discount entries created.
        VerifyPaymentToleranceEntry(
          GenJournalLine."Account No.", AppliedVendorEntryDocumentType, -SignFactor * Currency."Max. Payment Tolerance Amount");
        VerifyPaymentDiscountEntry(
          GenJournalLine."Account No.", AppliedVendorEntryDocumentType, -SignFactor * DiscountAmount);
    end;

    local procedure AddDocumentNumberToJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate(
          "Document No.", GenJournalLine."Journal Batch Name" + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
    end;

    local procedure AppliesDocumentGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AppliesToDocNo: Code[20])
    begin
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    [Normal]
    local procedure ApplyLedgerEntryCreditInvoice(var ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; AmountToApply: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(ApplyingVendorLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        LibraryERM.SetApplyVendorEntry(ApplyingVendorLedgerEntry, AmountToApply);

        // Find Posted Vendor Ledger Entries.
        VendorLedgerEntry.SetFilter(
          "Document Type", '%1|%2', VendorLedgerEntry."Document Type"::Invoice, VendorLedgerEntry."Document Type"::"Credit Memo");
        ApplyVendorLedgerEntry(VendorLedgerEntry, -AmountToApply, GenJournalLine."Account No.");
    end;

    [Normal]
    local procedure ApplyLedgerEntryPaymentRefund(var ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; AmountToApply: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(ApplyingVendorLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        LibraryERM.SetApplyVendorEntry(ApplyingVendorLedgerEntry, AmountToApply);

        // Find Posted Vendor Ledger Entries.
        VendorLedgerEntry.SetFilter(
          "Document Type", '%1|%2', VendorLedgerEntry."Document Type"::Payment, VendorLedgerEntry."Document Type"::Refund);
        ApplyVendorLedgerEntry(VendorLedgerEntry, AmountToApply, GenJournalLine."Account No.");
    end;

    [Normal]
    local procedure ApplyVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AmountToApply: Decimal; VendorNo: Code[20])
    begin
        // Find Posted Vendor Ledger Entries.
        VendorLedgerEntry.SetRange("Applying Entry", false);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.Validate("Amount to Apply", AmountToApply);
            VendorLedgerEntry.Modify(true);
        until VendorLedgerEntry.Next() = 0;

        // Set Applies-to ID.
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
    end;

    local procedure ApplyVendorLedgerWithTolerance(var VendorLedgerEntry: Record "Vendor Ledger Entry"; Amount: Decimal; AcceptedPaymentTolerance: Decimal)
    begin
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, Amount);
        VendorLedgerEntry.Validate("Accepted Payment Tolerance", AcceptedPaymentTolerance);
        VendorLedgerEntry.Validate("Accepted Pmt. Disc. Tolerance", true);
        VendorLedgerEntry.Modify(true);
    end;

    [Normal]
    local procedure CalcRmngAmtForApplngEntry(var DeltaAssert: Codeunit "Delta Assert"; var TempGenJournalLine: Record "Gen. Journal Line" temporary; NoOfLines: Integer; ApplicationAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Watch Remaining Amount expected value should be change after Delta amount application.
        TempGenJournalLine.FindFirst();
        VendorLedgerEntry.SetRange("Document No.", TempGenJournalLine."Document No.");
        VendorLedgerEntry.FindFirst();
        DeltaAssert.AddWatch(
          DATABASE::"Vendor Ledger Entry", VendorLedgerEntry.GetPosition(), VendorLedgerEntry.FieldNo("Remaining Amount"),
          VendorLedgerEntry.Amount - ApplicationAmount * NoOfLines);
    end;

    [Normal]
    local procedure CalcRmngAmtForApplOnSameEntry(var DeltaAssert: Codeunit "Delta Assert"; var GenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Watch Remaining Amount expected value should remain same after Delta amount application on same entry.
        GenJournalLine.FindSet();
        repeat
            VendorLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
            VendorLedgerEntry.FindFirst();
            DeltaAssert.AddWatch(
              DATABASE::"Vendor Ledger Entry", VendorLedgerEntry.GetPosition(), VendorLedgerEntry.FieldNo("Remaining Amount"), 0);
        until GenJournalLine.Next() = 1;
    end;

    [Normal]
    local procedure CalcRmngAmtForSameDirection(var DeltaAssert: Codeunit "Delta Assert"; var TempGenJournalLine: Record "Gen. Journal Line" temporary; ApplicationAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Watch Remaining Amount expected value should be change after Delta amount application.
        TempGenJournalLine.FindSet();
        repeat
            VendorLedgerEntry.SetRange("Document No.", TempGenJournalLine."Document No.");
            VendorLedgerEntry.FindFirst();
            DeltaAssert.AddWatch(
              DATABASE::"Vendor Ledger Entry", VendorLedgerEntry.GetPosition(), VendorLedgerEntry.FieldNo("Remaining Amount"),
              VendorLedgerEntry.Amount + ApplicationAmount);
        until TempGenJournalLine.Next() = 0;
    end;

    local procedure ChangePaymentToleranceCurrency(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
        ChangePaymentTolerance: Report "Change Payment Tolerance";
    begin
        // Change random Payment Tolerance.
        Currency.Get(CurrencyCode);
        Clear(ChangePaymentTolerance);
        ChangePaymentTolerance.InitializeRequest(
          false, Currency.Code, LibraryRandom.RandInt(5), 100 + LibraryRandom.RandDec(100, 2));
        ChangePaymentTolerance.UseRequestPage(false);
        ChangePaymentTolerance.Run();
    end;

    local procedure ChangePostingDateInJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    begin
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateCurrencyExchangeRate(CurrencyCode: Code[10]; MultiplicationFactor: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, WorkDate());
        // Validate any random Exchange Rate Amount greater than 10.
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 10 + LibraryRandom.RandDec(1000, 2));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount" * MultiplicationFactor);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateCurrencyWithAccounts(var Currency: Record Currency)
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
    end;

    local procedure CreateCurrencyWithExchange(var AmountRoundingPrecision: Decimal; MultiplicationFactor: Decimal): Code[10]
    var
        Currency: Record Currency;
    begin
        CreateCurrencyWithAccounts(Currency);
        CreateCurrencyExchangeRate(Currency.Code, MultiplicationFactor);
        AmountRoundingPrecision := Currency."Amount Rounding Precision";
        exit(Currency.Code);
    end;

    [Normal]
    local procedure CreateDocumentLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch"; NumberOfLines: Integer; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; Amount: Decimal)
    var
        Counter: Integer;
    begin
        for Counter := 1 to NumberOfLines do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
              GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
            AddDocumentNumberToJournalLine(GenJournalLine);
        end;
    end;

    local procedure CreateLineWhichWillBeApplied(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        AccountNo: Code[20];
    begin
        // Get the Line No 10000 as it is created automatically and create General Journal Line as per parameter passed.
        AccountNo := GenJournalLine."Account No.";
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", 10000);
        GenJournalLine.Validate("Account No.", AccountNo);
        GenJournalLine.Validate("Document Type", DocumentType);
        GenJournalLine.Validate(Amount, -Amount);
        AddDocumentNumberToJournalLine(GenJournalLine);
    end;

    local procedure CreatePaymentTermsWithDiscount(var PaymentTerms: Record "Payment Terms")
    var
        NoOfDays: Integer;
    begin
        // Input any random Due Date and Discount Date Calculation and Discount %.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        NoOfDays := 5 + LibraryRandom.RandInt(5);  // Add 5 to have larger value.
        Evaluate(PaymentTerms."Due Date Calculation", '<' + Format(NoOfDays) + 'M>');
        Evaluate(PaymentTerms."Discount Date Calculation", '<' + Format(NoOfDays - 1) + 'D>');
        PaymentTerms.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);
    end;

    local procedure CreatePostGeneralJournalLines(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentTerms: Record "Payment Terms";
        VendorNo: Code[20];
        Counter: Integer;
    begin
        // Create 2 to 5 lines of Type Invoice/Refund and Credit Memo/Payment each.
        CreateJournalBatchWithAccount(GenJournalBatch);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        VendorNo := CreateVendorWithPaymentTerms(PaymentTerms.Code);

        for Counter := 1 to 1 + LibraryRandom.RandInt(4) do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
              GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandDec(10000, 2));
            AddDocumentNumberToJournalLine(GenJournalLine);
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType2,
              GenJournalLine."Account Type"::Vendor, VendorNo, -GenJournalLine.Amount);
            AddDocumentNumberToJournalLine(GenJournalLine);
        end;

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Normal]
    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithPaymentTerms(PaymentTermsCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateJournalBatchWithAccount(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, FindGeneralJournalTemplate());
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateVendorWithApplyToOldest(): Code[20]
    var
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Application Method", Vendor."Application Method"::"Apply to Oldest");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateAndPostGeneralLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; Amount: Decimal; DocumentType: Enum "Gen. Journal Document Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, FindGeneralJournalTemplate());
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Vendor, AccountNo, Amount);
        ModifyGeneralLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.
    end;

    local procedure CreateAndPostPayment(var GenJournalLine: Record "Gen. Journal Line"; BalAccountNo: Code[20]; AppliestoDocNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccountNo: Code[20];
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, FindGeneralJournalTemplate());
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount);
        AddDocumentNumberToJournalLine(GenJournalLine);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::Vendor);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        AppliesDocumentGenJournalLine(GenJournalLine, AppliestoDocNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryUtility.GenerateGUID(); // Hack to fix problem with GenerateGUID.
    end;

    local procedure FindGeneralJournalTemplate(): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        exit(GenJournalTemplate.Name);
    end;

    local procedure FindVendorLedgerEntriesAmount(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type") Amount: Decimal
    begin
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.CalcFields("Remaining Amount");
            Amount += VendorLedgerEntry."Remaining Amount";
        until VendorLedgerEntry.Next() = 0;
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Remaining Amount", Amount);
    end;

    local procedure FindGLAccount(GenPostingType: Enum "General Posting Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("Gen. Posting Type", GenPostingType);
        exit(LibraryERM.FindDirectPostingGLAccount(GLAccount));
    end;

    local procedure InputCurrencyInGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10])
    begin
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure ModifyGeneralLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        AddDocumentNumberToJournalLine(GenJournalLine);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", FindGLAccount(GenJournalLine."Gen. Posting Type"::Purchase));
        GenJournalLine.Modify(true);
    end;

    local procedure SaveGenJnlLineInTempTable(var NewGenJournalLine: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindSet();
        repeat
            NewGenJournalLine := GenJournalLine;
            NewGenJournalLine.Insert();
        until GenJournalLine.Next() = 0;
    end;

    local procedure SetAppliesToIDInGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate("Applies-to ID", UserId);
        GenJournalLine.Modify(true);
    end;

    local procedure SetApplyVendorEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.CalcFields("Remaining Amount");
            VendorLedgerEntry.Validate("Applying Entry", true);
            VendorLedgerEntry.Validate("Applies-to ID", UserId);
            VendorLedgerEntry.Validate("Amount to Apply", VendorLedgerEntry."Remaining Amount");
            VendorLedgerEntry.Modify(true);
            CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendorLedgerEntry);
        until VendorLedgerEntry.Next() = 0;
    end;

    [Normal]
    local procedure VerifyAllVendorEntriesStatus(var GenJournalLine: Record "Gen. Journal Line"; Open: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        GenJournalLine.FindSet();
        repeat
            VendorLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
            VendorLedgerEntry.FindFirst();
            VendorLedgerEntry.TestField(Open, Open);
        until GenJournalLine.Next() = 0;
    end;

    local procedure VerifyAmountLargerError(EntryNo: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        Assert.AreEqual(
          StrSubstNo(
            AmountToApplyLargerError, VendorLedgerEntry.FieldCaption("Amount to Apply"),
            VendorLedgerEntry.FieldCaption("Remaining Amount"), VendorLedgerEntry.TableCaption(),
            VendorLedgerEntry.FieldCaption("Entry No."), EntryNo),
          GetLastErrorText,
          UnknownError);
    end;

    local procedure VerifyAmountSameSignError(EntryNo: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        Assert.AreEqual(
          StrSubstNo(
            AmountToApplyHaveSameSignError, VendorLedgerEntry.FieldCaption("Amount to Apply"),
            VendorLedgerEntry.FieldCaption("Remaining Amount"), VendorLedgerEntry.TableCaption(),
            VendorLedgerEntry.FieldCaption("Entry No."), EntryNo),
          GetLastErrorText,
          UnknownError);
    end;

    local procedure VerifyDetailedVendorLedger(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    begin
        DetailedVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DetailedVendorLedgEntry.SetRange("Document Type", DocumentType);
        DetailedVendorLedgEntry.FindFirst();
        DetailedVendorLedgEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyPaymentToleranceEntry(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::"Payment Tolerance");
        VerifyDetailedVendorLedger(DetailedVendorLedgEntry, VendorNo, DocumentType, Amount);
    end;

    local procedure VerifyPaymentDiscountEntry(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance");
        VerifyDetailedVendorLedger(DetailedVendorLedgEntry, VendorNo, DocumentType, Amount);
    end;

    local procedure VerifyRemainingAmountInLedger(VendorLedgerEntry: Record "Vendor Ledger Entry"; AmountApplied: Decimal)
    begin
        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.CalcFields("Remaining Amount", Amount);
        VendorLedgerEntry.TestField("Remaining Amount", VendorLedgerEntry.Amount - AmountApplied);
        Assert.AreNotEqual(
          VendorLedgerEntry.Amount, VendorLedgerEntry."Remaining Amount",
          StrSubstNo(AmountMustNotBeEqual, VendorLedgerEntry.FieldCaption(Amount), VendorLedgerEntry.FieldCaption("Remaining Amount")));
    end;

    local procedure VerifyRemainingAmountInEntries(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type");
        VendorLedgerEntry.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
        repeat
            VendorLedgerEntry.CalcFields("Remaining Amount", Amount);
            VendorLedgerEntry.TestField("Remaining Amount", 0);
            Assert.AreNotEqual(
              VendorLedgerEntry.Amount, VendorLedgerEntry."Remaining Amount",
              StrSubstNo(AmountMustNotBeEqual, VendorLedgerEntry.FieldCaption(Amount), VendorLedgerEntry.FieldCaption("Remaining Amount")));
        until VendorLedgerEntry.Next() = 0;
    end;

    local procedure VerifyVendorLedgerEntry(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", 0);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

