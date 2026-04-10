codeunit 133771 "Remittance REP Check UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report] [Remittance Advice - Journal]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('RemittanceAdviceJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPrintLoopRemittanceAdviceJournal()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate PrintLoop - OnAfterGetRecord Trigger of Report 399 - Remittance Advice - Journal.

        // Setup: Create General Journal Line, Vendor Ledger Entries and Detailed Vendor Ledger Entry.
        Initialize();
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, CreateVendor());
        CreateVendorLedgerEntry(
          VendorLedgerEntry, GenJournalLine."Applies-to ID", GenJournalLine."Account No.", VendorLedgerEntry."Document Type");
        CreateVendorLedgerEntry(
          VendorLedgerEntry2, GenJournalLine."Applies-to ID", GenJournalLine."Account No.", VendorLedgerEntry."Document Type");
        CreateDetailedVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry2."Entry No.", DetailedVendorLedgEntry."Entry Type"::Application,
          DetailedVendorLedgEntry."Document Type"::"Credit Memo", 1);

        // Exercise.
        REPORT.Run(REPORT::"Remittance Advice - Journal");

        // Verify: Verify General Journal Line Amount and Print Loop Number on Report - Remittance Advice - Journal.
        LibraryReportDataset.LoadDataSetFile();
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        LibraryReportDataset.AssertElementWithValueExists('Amt_GenJournalLine', GenJournalLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('PrintLoopNumber', VendorLedgerEntry.Count);
    end;

    [Test]
    [HandlerFunctions('RemittanceAdviceEntriesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordRemittanceAdviceEntries()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        EntryNo: Integer;
        Amount: Decimal;
    begin
        // Purpose of the test is to validate VendLedgEntry - OnAfterGetRecord Trigger of Report 400 - Remittance Advice - Entries.

        // Setup: Create Vendor Ledger Entries and Detailed Vendor Ledger Entries.
        Initialize();
        EntryNo := CreateAndUpdateMultipleVendorLedgerEntries(VendorLedgerEntry, VendorLedgerEntry2);
        CreateDetailedVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Entry No.", DetailedVendorLedgEntry."Entry Type"::"Payment Discount",
          DetailedVendorLedgEntry."Document Type"::Payment, 1);
        Amount :=
          CreateDetailedVendorLedgerEntry(
            VendorLedgerEntry2, VendorLedgerEntry2."Entry No.", DetailedVendorLedgEntry."Entry Type"::Application,
            DetailedVendorLedgEntry."Document Type"::Payment, 1);
        CreateDetailedVendorLedgerEntry(
          VendorLedgerEntry2, EntryNo, DetailedVendorLedgEntry."Entry Type"::Application,
          DetailedVendorLedgEntry."Document Type"::"Credit Memo", 1);

        // Exercise.
        REPORT.Run(REPORT::"Remittance Advice - Entries");

        // Verify: Verify Vendor No, Vendor Ledger Entry Number and Line Amount with Discount Currency on Report - Remittance Advice - Entries.
        VendorLedgerEntry.CalcFields(Amount);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VendorLedgerEntryVendorNo', VendorLedgerEntry."Vendor No.");
        LibraryReportDataset.AssertElementWithValueExists('LAmountWDiscCur', -(Amount + VendorLedgerEntry2."Pmt. Disc. Rcd.(LCY)"));
        LibraryReportDataset.AssertElementWithValueExists('VendLedgerEntryNo_DtldVendLedgEntry', VendorLedgerEntry2."Entry No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CurrencyCodeRemittanceAdviceEntries()
    var
        RemittanceAdviceEntries: Report "Remittance Advice - Entries";
        CurrencyCode: Code[10];
    begin
        // Purpose of the test is to validate CurrencyCode function of Report 400 - Remittance Advice - Entries.

        // Setup.
        Initialize();
        CurrencyCode := LibraryUTUtility.GetNewCode10();

        // Exercise & Verify: Execute function - CurrencyCode. Verify Currency Code with return value of function.
        Assert.AreEqual(CurrencyCode, RemittanceAdviceEntries.CurrencyCode(CurrencyCode), 'Value must be equal.');
    end;

    [Test]
    [HandlerFunctions('RemittanceAdviceJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RemittanceAdviceEntrieShouldAllPayedDocumentsWithPartiallyPaid()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Remittance Advice - Journal]
        // [SCENARIO 380011] The report should list the payed documents and the Remaining Amount should be shown only for documents that will be partially paid.

        Initialize();

        // [GIVEN] Payment Gen. Journal Line for vendor
        CreateGeneralJournalLineWithCurrencyCode(GenJournalLine, GenJournalLine."Account Type"::Vendor);

        // [GIVEN] Invoice Vendor Ledger Entry with "Original Amount" = 1000, "Remaining Amount" = 1000 and "Amount to apply" = 1000
        MockVendorLedgerEntryWithDetailedEntry(
          VendorLedgerEntry, GenJournalLine, VendorLedgerEntry."Document Type"::Invoice,
          DetailedVendorLedgEntry."Entry Type"::"Initial Entry", -1);

        // [GIVEN] Credit Memo Vendor Ledger Entry with "Original Amount" = 2000, "Remaining Amount" = 2000 and "Amount to apply" = 2000
        MockVendorLedgerEntryWithDetailedEntry(
          VendorLedgerEntry, GenJournalLine, VendorLedgerEntry."Document Type"::"Credit Memo",
          DetailedVendorLedgEntry."Entry Type"::"Initial Entry", 1);

        // [GIVEN] Apply partially paid to Credit Memo Vendor Ledger Entry with "Original Amount" = 2000, "Remaining Amount" = 2000 and "Amount to apply" = 1500
        VendorLedgerEntry."Amount to Apply" := Round(VendorLedgerEntry."Remaining Amount" / LibraryRandom.RandIntInRange(2, 3));
        VendorLedgerEntry.Modify();

        // [GIVEN] Update Balance in the Payment Gen. Journal Line
        UpdateGenJournalLineBalanceAmount(VendorLedgerEntry, GenJournalLine);

        // [WHEN] Run report Remittance Advice - Journal
        Commit();
        REPORT.Run(REPORT::"Remittance Advice - Journal");

        // [THEN] Verify the report should list the payed credit memo and invoice with following values:
        // [THEN] credit memo with "Original Amount" = 2000, "Remaining Amount" = 500 and invoice with "Original Amount" = 1000, "Remaining Amount" = 0
        VerifyPayedDocumentsAndPartiallyPaid(VendorLedgerEntry, GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('RemittanceAdviceJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RemittanceAdviceEntrieShouldAllPayedDocumentsWithoutPartiallyPaid()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Remittance Advice - Journal]
        // [SCENARIO 380011] The report should list the payed documents without partially paid

        Initialize();

        // [GIVEN] Payment Gen. Journal Line for vendor
        CreateGeneralJournalLineWithCurrencyCode(GenJournalLine, GenJournalLine."Account Type"::Vendor);

        // [GIVEN] Invoice Vendor Ledger Entry with "Original Amount" = 1000, "Remaining Amount" = 1000 and "Amount to apply" = 1000
        MockVendorLedgerEntryWithDetailedEntry(
          VendorLedgerEntry, GenJournalLine, VendorLedgerEntry."Document Type"::Invoice,
          DetailedVendorLedgEntry."Entry Type"::"Initial Entry", -1);

        // [GIVEN] Credit Memo Vendor Ledger Entry with "Original Amount" = 2000, "Remaining Amount" = 2000 and "Amount to apply" = 2000
        MockVendorLedgerEntryWithDetailedEntry(
          VendorLedgerEntry, GenJournalLine, VendorLedgerEntry."Document Type"::"Credit Memo",
          DetailedVendorLedgEntry."Entry Type"::"Initial Entry", 1);

        // [GIVEN] Apply Vendor Ledger Entries to Payment Gen. Journal Line
        UpdateGenJournalLineBalanceAmount(VendorLedgerEntry, GenJournalLine);

        // [WHEN] Run report Remittance Advice - Journal
        Commit();
        REPORT.Run(REPORT::"Remittance Advice - Journal");

        // [THEN] Verify the report should list the payed credit memo and invoice with following values:
        // [THEN] credit memo with "Original Amount" = 2000, "Remaining Amount" = 0 and invoice with "Original Amount" = 1000, "Remaining Amount" = 0
        VerifyPayedDocumentsAndPartiallyPaid(VendorLedgerEntry, GenJournalLine);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Enqueue value for Request Page handler - RemittanceAdviceJournalRequestPageHandler or RemittanceAdviceEntriesRequestPageHandler.
        exit(Vendor."No.");
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AppliesToID: Code[50]; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        VendorLedgerEntry."Entry No." := SelectVendorLedgerEntryNo();
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Applies-to ID" := AppliesToID;
        VendorLedgerEntry."Document Type" := DocumentType;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();
    end;

    local procedure CreateAndUpdateMultipleVendorLedgerEntries(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var VendorLedgerEntry2: Record "Vendor Ledger Entry"): Integer
    var
        VendorLedgerEntry3: Record "Vendor Ledger Entry";
    begin
        CreateVendorLedgerEntry(VendorLedgerEntry, '', CreateVendor(), VendorLedgerEntry."Document Type"::Payment);  // Blank value for Applies To ID.
        CreateVendorLedgerEntry(
          VendorLedgerEntry2, VendorLedgerEntry."Applies-to ID", VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Document Type");
        VendorLedgerEntry2."Pmt. Disc. Rcd.(LCY)" := LibraryRandom.RandDec(5, 2);
        VendorLedgerEntry2.Modify();
        CreateVendorLedgerEntry(VendorLedgerEntry3, '', VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Document Type"::"Credit Memo");  // Blank value for Applies To ID.
        UpdateVendorLedgerEntryClosedByEntryNo(VendorLedgerEntry, VendorLedgerEntry2."Entry No.");
        UpdateVendorLedgerEntryClosedByEntryNo(VendorLedgerEntry2, VendorLedgerEntry."Entry No.");
        LibraryVariableStorage.Enqueue(VendorLedgerEntry."Entry No.");  // Enqueue value for - RemittanceAdviceEntriesRequestPageHandler.
        exit(VendorLedgerEntry3."Entry No.");
    end;

    local procedure CreateDetailedVendorLedgerEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"; AppliedVendLedgerEntryNo: Integer; EntryType: Enum "Detailed CV Ledger Entry Type"; DocumentType: Enum "Gen. Journal Document Type"; Sign: Integer): Decimal
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry."Entry No." := SelectDetailedVendorLedgerEntryNo();
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        DetailedVendorLedgEntry."Document Type" := DocumentType;
        DetailedVendorLedgEntry."Document No." := VendorLedgerEntry."Document No.";
        DetailedVendorLedgEntry."Entry Type" := EntryType;
        DetailedVendorLedgEntry.Amount := LibraryRandom.RandDec(10, 2) * Sign;
        DetailedVendorLedgEntry."Amount (LCY)" := DetailedVendorLedgEntry.Amount;
        DetailedVendorLedgEntry."Applied Vend. Ledger Entry No." := AppliedVendLedgerEntryNo;
        DetailedVendorLedgEntry."Initial Document Type" := VendorLedgerEntry."Document Type";
        DetailedVendorLedgEntry.Insert(true);
        exit(DetailedVendorLedgEntry.Amount);
    end;

    local procedure MockVendorLedgerEntryWithDetailedEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; EntryType: Enum "Detailed CV Ledger Entry Type"; Sign: Integer)
    begin
        CreateVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Applies-to ID", GenJournalLine."Account No.", DocumentType);
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Entry No.", EntryType, DocumentType, Sign);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry."Amount to Apply" := VendorLedgerEntry."Remaining Amount";
        VendorLedgerEntry."Currency Code" := GenJournalLine."Currency Code";
        VendorLedgerEntry.Modify();
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplateAndBatch(GenJournalBatch);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine."Bal. Account No." := GenJournalLine."Account No.";
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Computer Check";
        GenJournalLine."Applies-to ID" := LibraryUTUtility.GetNewCode();
        GenJournalLine.Amount := LibraryRandom.RandDec(10, 2);
        GenJournalLine.Insert();

        // Enqueue value for Request Page handler
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
    end;

    local procedure CreateGenJournalTemplateAndBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate.Insert();
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        GenJournalBatch.Insert();
    end;

    local procedure CreateGeneralJournalLineWithCurrencyCode(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type")
    begin
        CreateGeneralJournalLine(GenJournalLine, AccountType, CreateVendor());
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        GenJournalLine.Validate(Amount, 0);
        GenJournalLine.Modify(true);
    end;

    local procedure SelectDetailedVendorLedgerEntryNo(): Integer
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        if DetailedVendorLedgEntry.FindLast() then
            exit(DetailedVendorLedgEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure SelectVendorLedgerEntryNo(): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if VendorLedgerEntry.FindLast() then
            exit(VendorLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure UpdateVendorLedgerEntryClosedByEntryNo(VendorLedgerEntry: Record "Vendor Ledger Entry"; EntryNo: Integer)
    begin
        VendorLedgerEntry."Closed by Entry No." := EntryNo;
        VendorLedgerEntry.Modify();
    end;

    local procedure UpdateGenJournalLineBalanceAmount(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.CalcSums("Amount to Apply");
        GenJournalLine.Validate(Amount, -VendorLedgerEntry."Amount to Apply");
        GenJournalLine.Modify(true);
    end;

    local procedure VerifyPayedDocumentsAndPartiallyPaid(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.CalcFields("Remaining Amount");
            LibraryReportDataset.AssertElementWithValueExists(
              'AppliedVendLedgEntryTempRemainingAmt', -(VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry."Amount to Apply"));
            LibraryReportDataset.AssertElementWithValueExists('AppliedVendLedgEntryTempDocType', Format(VendorLedgerEntry."Document Type"));
        until VendorLedgerEntry.Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RemittanceAdviceJournalRequestPageHandler(var RemittanceAdviceJournal: TestRequestPage "Remittance Advice - Journal")
    var
        JournalTemplateName: Variant;
        JournalBatchName: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        RemittanceAdviceJournal.FindVendors.SetFilter("Journal Template Name", JournalTemplateName);
        RemittanceAdviceJournal.FindVendors.SetFilter("Journal Batch Name", JournalBatchName);
        RemittanceAdviceJournal.Vendor.SetFilter("No.", No);
        RemittanceAdviceJournal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RemittanceAdviceEntriesRequestPageHandler(var RemittanceAdviceEntries: TestRequestPage "Remittance Advice - Entries")
    var
        EntryNo: Variant;
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(EntryNo);
        RemittanceAdviceEntries."Vendor Ledger Entry".SetFilter("Vendor No.", VendorNo);
        RemittanceAdviceEntries."Vendor Ledger Entry".SetFilter("Entry No.", Format(EntryNo));
        RemittanceAdviceEntries.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

