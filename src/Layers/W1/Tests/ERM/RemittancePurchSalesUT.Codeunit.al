codeunit 133772 "Remittance Purch & Sales UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Remittance Advice] [UT]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        CurrentSaveValuesId: Integer;

    [Test]
    [HandlerFunctions('RemittanceAdviceJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordRemittanceAdviceJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO] PrintLoop - OnAfterGetRecord Trigger of Report 399 - Remittance Advice - Journal.
        // [GIVEN] Create General Journal Line and Vendor Ledger Entry.
        Initialize();
        CreateGeneralJournalLine(GenJournalLine);
        CreateVendorLedgerEntry(
          VendorLedgerEntry, GenJournalLine."Applies-to ID", GenJournalLine."Account No.", false, GenJournalLine.Amount,
          VendorLedgerEntry."Document Type"::Invoice);  // Print Vendor Ledger Details - False.

        // [WHEN] Run "Remittance Advice - Journal" report
        REPORT.Run(REPORT::"Remittance Advice - Journal");  // Opens handler - RemittanceAdviceJournalRequestPageHandler.

        // [THEN] Verify Amount and Remaining Pmt. Disc. Possible on Report - Remittance Advice - Journal.
        LibraryReportDataset.LoadDataSetFile();
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        LibraryReportDataset.AssertElementWithValueExists('Amt_GenJournalLine', GenJournalLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('PmdDiscRec', 0);
    end;

    [Test]
    [HandlerFunctions('RemittanceAdviceJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RemittanceAdviceJournalTotalAmount()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO 363914] TotalAmount is printed as summarized amount per Vendor
        Initialize();

        // [GIVEN] Two Gen. Journal lines with Amounts = "X" and "Y" for the same Vendor
        CreateGenJournalTemplateAndBatch(GenJournalBatch);
        VendorNo := CreateVendor();
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");

        Amount := CreateGeneralJournalLineForBatch(GenJournalLine, GenJournalBatch, VendorNo);
        CreateVendorLedgerEntry(
          VendorLedgerEntry, GenJournalLine."Applies-to ID", GenJournalLine."Account No.", false,
          GenJournalLine.Amount, VendorLedgerEntry."Document Type"::Invoice);
        Amount += CreateGeneralJournalLineForBatch(GenJournalLine, GenJournalBatch, VendorNo);
        CreateVendorLedgerEntry(
          VendorLedgerEntry, GenJournalLine."Applies-to ID", GenJournalLine."Account No.", false,
          GenJournalLine.Amount, VendorLedgerEntry."Document Type"::Invoice);

        // [WHEN] Run "Remittance Advice - Journal" report
        REPORT.Run(REPORT::"Remittance Advice - Journal");

        // [THEN] Total Amount on Remittance Advice - Journal Report is equal to "X" + "Y"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', Amount);
    end;

    [Test]
    [HandlerFunctions('RemittanceAdviceJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RemittanceAdviceJournalWithInvoicesInDiffCurrencies()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        CurrencyCode: Code[10];
        ExtDocNoCur: Code[35];
        Amount: Decimal;
        ExchRate: Decimal;
        AmountLCY: Decimal;
        AmountCur: Decimal;
    begin
        // [SCENARIO 380297] Remittance Advice - Journal with two invoices when Original Amount of first invoice in currency greater than Payment Amount
        Initialize();

        CreateGenJournalTemplateAndBatch(GenJournalBatch);
        VendorNo := CreateVendor();
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");

        // [GIVEN] Payment Journal Line with Amount in local currency = 30
        // [GIVEN] Invoice Vendor Ledger Entry "Inv1" in currency "C" with Amount = 100, Amount LCY = 10
        // [GIVEN] Invoice Vendor Ledger Entry "Inv2" in local currency with Amount = 20
        ExchRate := LibraryRandom.RandDecInRange(5, 10, 2);
        CurrencyCode :=
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchRate, ExchRate);
        Amount := CreateGeneralJournalLineForBatch(GenJournalLine, GenJournalBatch, VendorNo);
        AmountLCY := Round(Amount / LibraryRandom.RandIntInRange(2, 3));
        AmountCur := Round((Amount - AmountLCY) * ExchRate);

        CreateVendorLedgerEntryWithCurrency(
          VendorLedgerEntry, GenJournalLine."Applies-to ID", GenJournalLine."Account No.",
          -AmountCur, VendorLedgerEntry."Document Type"::Invoice, CurrencyCode);
        ExtDocNoCur := VendorLedgerEntry."External Document No.";

        CreateVendorLedgerEntryWithCurrency(
          VendorLedgerEntry, GenJournalLine."Applies-to ID", GenJournalLine."Account No.",
          -AmountLCY, VendorLedgerEntry."Document Type"::Invoice, '');

        // Required inside DayBookVendorLedgerEntryRequestPageHandler.
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run "Remittance Advice - Journal" report
        REPORT.Run(REPORT::"Remittance Advice - Journal");

        // [THEN] "Inv1" is printed with Original Amount = 100, Remaining Amount = 0, Payment Curr. Amount = 10
        LibraryReportDataset.LoadDataSetFile();
        VerifyRemittanceAdviceJournalValues(ExtDocNoCur, AmountCur, Amount - AmountLCY, CurrencyCode);
        // [THEN] "Inv2" is printed with Original Amount = 20, Remaining Amount = 0, Payment Curr. Amount = 20
        VerifyRemittanceAdviceJournalValues(VendorLedgerEntry."External Document No.", AmountLCY, AmountLCY, '');
    end;

    [Test]
    [HandlerFunctions('RemittanceAdviceJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordRemittanceAdviceJournalWithPartialAmount()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO] validate PrintLoop - OnAfterGetRecord Trigger of Report 399 - Remittance Advice - Journal.
        Initialize();

        // [GIVEN] Create General Journal Line and Vendor Ledger Entry.
        CreateGeneralJournalLine(GenJournalLine);

        // [GIVEN] Print Vendor Ledger Details - False and using partial Amount to Apply.
        CreateVendorLedgerEntry(
          VendorLedgerEntry, GenJournalLine."Applies-to ID", GenJournalLine."Account No.", false, GenJournalLine.Amount / 2,
          VendorLedgerEntry."Document Type"::Invoice);
        CreateAndUpdateDetailedVendorLedgerEntry(VendorLedgerEntry, DetailedVendorLedgEntry."Entry Type"::"Initial Entry");

        // [WHEN] Run "Remittance Advice - Journal" report
        REPORT.Run(REPORT::"Remittance Advice - Journal");  // Opens handler - RemittanceAdviceJournalRequestPageHandler.

        // [THEN] Verify Amount, Original Amount and Remaining Pmt. Disc. Possible on Report - Remittance Advice - Journal.
        VendorLedgerEntry.CalcFields("Original Amount");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Amt_GenJournalLine', GenJournalLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('AppliedVendLedgEntryTempOriginalAmt', -VendorLedgerEntry."Original Amount");
        LibraryReportDataset.AssertElementWithValueExists('PmdDiscRec', VendorLedgerEntry."Remaining Pmt. Disc. Possible");
    end;

    [Test]
    [HandlerFunctions('RemittanceAdviceEntriesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVendorLedgerEntriesRemittanceAdviceEntries()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO] verify vendor No. after run report - 400 - Remittance Advice - Entries.
        Initialize();
        // [GIVEN] Create Vendor and Detailed Vendor Ledger Entry.
        CreateVendorLedgerEntry(
          VendorLedgerEntry, '', CreateVendor(), false, LibraryRandom.RandDec(10, 2), VendorLedgerEntry."Document Type"::Payment);  // Print Vendor Ledger Details - False and using partial Amount to Apply.
        CreateAndUpdateDetailedVendorLedgerEntry(VendorLedgerEntry, DetailedVendorLedgEntry."Entry Type"::Application);
        CreateAndUpdateDetailedVendorLedgerEntry(VendorLedgerEntry, DetailedVendorLedgEntry."Entry Type"::"Payment Discount");

        // [WHEN] Run "Remittance Advice - Entries" report
        REPORT.Run(REPORT::"Remittance Advice - Entries");

        // [THEN] Verifying Vendor No. on Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VendorLedgerEntryVendorNo', VendorLedgerEntry."Vendor No.");
    end;

    [Test]
    [HandlerFunctions('RemittanceAdviceJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RemittanceAdviceJournalRemainingAndPaidAmount()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceNo: array[2] of Code[20];
        PaymentNo: Code[20];
        VendorNo: Code[20];
        InvoiceAmount: array[2] of Decimal;
        PaidAmount: array[2] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 371660] Report "Remittance Advice - Entries" shows expected Remaining Amount and Paid Amount for Gen. Journal lines partially applied and having same Document No.
        Initialize();

        // [GIVEN] Posted invoice "Inv1" with Amount "IAmt1" = 100.
        // [GIVEN] Posted invoice "Inv2" with Amount "IAmt2" = 200.
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreateGenJournalTemplateAndBatch(GenJournalBatch);
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalBatch.Modify(true);

        for i := 1 to 2 do begin
            InvoiceAmount[i] := LibraryRandom.RandIntInRange(100, 200);
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
              GenJournalLine."Account Type"::Vendor, VendorNo, -InvoiceAmount[i]);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
            InvoiceNo[i] := GenJournalLine."Document No.";
            PaidAmount[i] := InvoiceAmount[i] - LibraryRandom.RandInt(50);
        end;

        // [GIVEN] Payment Gen. Journal Line applied to "Inv1" with Amount "PAmt1" = 90 and Document No. = "P1".
        // [GIVEN] Payment Gen. Journal Line applied to "Inv2" with Amount "PAmt2" = 160 and Document No. = "P1".
        CreatePaymentGenJnlLine(GenJournalLine, InvoiceNo[1], PaidAmount[1]);
        PaymentNo := GenJournalLine."Document No.";
        CreatePaymentGenJnlLine(GenJournalLine, InvoiceNo[2], PaidAmount[2]);
        GenJournalLine.Validate("Document No.", PaymentNo);
        GenJournalLine.Modify(true);

        // [WHEN] Run "Remittance Advice - Entries" report for mentioned payment lines.
        Commit();
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        REPORT.Run(REPORT::"Remittance Advice - Journal");

        // [THEN] Verify resulting dataset has Remaining Amounts 10 and 40, Paid Amounts 90 and 160.
        LibraryReportDataset.LoadDataSetFile();
        VerifyRemittanceAdviceJournalRemainingAndPaidAmounts(InvoiceAmount[1], PaidAmount[1]);
        VerifyRemittanceAdviceJournalRemainingAndPaidAmounts(InvoiceAmount[2], PaidAmount[2]);
    end;

    [Test]
    [HandlerFunctions('RemittanceAdviceEntriesNoParamsRequestPageHandler')]
    procedure AppliedAmountOnRemittanceAdviceEntriesReportWhenApplyUapplyApply()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        VendorNo: Code[20];
        XmlParameters: Text;
        InvoiceAmount: Decimal;
        AmountToApply: array[2] of Decimal;
    begin
        // [SCENARIO 423527] Applied Amount in report "Remittance Advice - Entries" results when Payment Vendor Ledger Entry is applied, then unapplied, then applied again.
        Initialize();

        // [GIVEN] Posted Purchase Invoice and posted Payment. Both have Vendor "V" and Amount 1000.
        VendorNo := LibraryPurchase.CreateVendorNo();
        InvoiceAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CreateGenJournalBatchWithTemplate(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, "Gen. Journal Document Type"::Invoice,
            "Gen. Journal Account Type"::Vendor, VendorNo, -InvoiceAmount);
        InvoiceNo := GenJournalLine."Document No.";
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, "Gen. Journal Document Type"::Payment,
            "Gen. Journal Account Type"::Vendor, VendorNo, InvoiceAmount);
        PaymentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Invoice fully applied to Payment. Then Invoice and Payment are unapplied.
        LibraryERM.ApplyVendorLedgerEntries("Gen. Journal Document Type"::Payment, "Gen. Journal Document Type"::Invoice, PaymentNo, InvoiceNo);
        UnapplyVendLedgerEntry("Gen. Journal Document Type"::Payment, PaymentNo);

        // [GIVEN] Invoice is partially applied to Payment twice. Amount to Apply is 100 and 200.
        AmountToApply[1] := LibraryRandom.RandDecInRange(100, 200, 2);
        AmountToApply[2] := LibraryRandom.RandDecInRange(100, 200, 2);
        ApplyVendorLedgerEntryWithAmount("Gen. Journal Document Type"::Payment, "Gen. Journal Document Type"::Invoice, PaymentNo, InvoiceNo, AmountToApply[1]);
        ApplyVendorLedgerEntryWithAmount("Gen. Journal Document Type"::Payment, "Gen. Journal Document Type"::Invoice, PaymentNo, InvoiceNo, AmountToApply[2]);

        // [WHEN] Run report "Remittance Advice - Entries" for Payment.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, "Gen. Journal Document Type"::Payment, PaymentNo);
        XmlParameters := Report.RunRequestPage(Report::"Remittance Advice - Entries");
        LibraryReportDataset.RunReportAndLoad(Report::"Remittance Advice - Entries", VendorLedgerEntry, XmlParameters);

        // [THEN] Last column "Amount" (which shows applied amount) for line with Invoice has value -(100 + 200) = -300.
        LibraryReportDataset.AssertElementWithValueExists('LAmountWDiscCur', -(AmountToApply[1] + AmountToApply[2]));
    end;

    [Test]
    [HandlerFunctions('CreatePaymentWithPostingModalPageHandler,RemittanceAdviceEntriesNoParamsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RemittanceAdviceEntriesWithInvoiceWithDiffCurrencyExchangeRate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccount: Record "Bank Account";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        PaymentJournal: TestPage "Payment Journal";
        VendorNo: Code[20];
        CurrencyCode: Code[10];
        ExchRate: Decimal;
        PaymentDiscAmount: Decimal;
        XmlParameters: Text;
    begin
        // [SCENARIO 453527] Report 400 is not calculating payment discount correctly when vendor is in foreign currency
        Initialize();

        // [GIVEN] Create Currency, Bank Account, Vendor
        ExchRate := LibraryRandom.RandDecInRange(5, 10, 2);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchRate, ExchRate);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
        VendorNo := CreateVendorWithPaymentTermsAndCurrency(CurrencyCode);

        // [GIVEN] Posted Purchase Invoice with Payment Discount
        CreateAndPostPurchaseInvoiceForVendorWithCurrency(VendorNo, CurrencyCode);

        // [GIVEN] Add New Exchange Rate to the currency 
        ExchRate += LibraryRandom.RandDec(1, 1);
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + LibraryRandom.RandInt(5), ExchRate, ExchRate);

        // Enqueue value for Request Page handler - CreatePaymentWithPostingModalPageHandler 
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(WorkDate());

        // [GIVEN] Post Payment for Vendor Invoice
        GenJournalLine.DeleteAll();
        PaymentJournal.Trap();
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Vendor No.", VendorNo);
        VendorLedgerEntries."Create Payment".Invoke();

        // [VERIFY] Vendor No. and Document Type as Payment
        PaymentJournal."Account No.".AssertEquals(VendorNo);
        PaymentJournal."Document Type".AssertEquals(GenJournalLine."Document Type"::Payment);
        PaymentJournal.Close();

        // [THEN] Filter and Post Payment Gen. Journal Line
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Account No.", VendorNo);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Payment);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(VendorNo);

        // [WHEN] Run report "Remittance Advice - Entries" for Payment.
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange(Open, false);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.FindFirst();
        XmlParameters := Report.RunRequestPage(Report::"Remittance Advice - Entries");
        LibraryReportDataset.RunReportAndLoad(Report::"Remittance Advice - Entries", VendorLedgerEntry, XmlParameters);

        // [VERIFY] Verify: Pmt. Disc. Taken column (which shows applied discount amount) with exact applied discount amount
        PaymentDiscAmount := GetPaymentDiscountAmountForeignCurrency(VendorLedgerEntry."Entry No.", VendorLedgerEntry."Document No.");
        LibraryReportDataset.AssertElementWithValueExists('LineDiscount_VendLedgEntry2', PaymentDiscAmount);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        DeleteObjectOptionsIfNeeded();
    end;

    local procedure ApplyVendorLedgerEntryWithAmount(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20]; AmountToApply: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, AmountToApply);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, DocumentType2, DocumentNo2);
        VendorLedgerEntry2.Validate("Amount to Apply", -AmountToApply);
        VendorLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplateAndBatch(GenJournalBatch);
        CreateGeneralJournalLineForBatch(GenJournalLine, GenJournalBatch, CreateVendor());

        // Enqueue value for Request Page handler - RemittanceAdviceJournalRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
    end;

    local procedure CreateGeneralJournalLineForBatch(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; VendorNo: Code[20]): Decimal
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(GenJournalLine);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, GenJournalLine.FieldNo("Line No."));
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        GenJournalLine."Account No." := VendorNo;
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine."Bal. Account No." := GenJournalLine."Account No.";
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Computer Check";
        GenJournalLine."Applies-to ID" := LibraryUTUtility.GetNewCode();
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine.Amount := LibraryRandom.RandDecInDecimalRange(20, 50, 2);
        GenJournalLine.Insert();
        exit(GenJournalLine.Amount);
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

    local procedure CreateGenJournalBatchWithTemplate(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", "Gen. Journal Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGLEntry(var GLEntry: Record "G/L Entry")
    var
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry2.FindLast();
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."G/L Account No." := LibraryUTUtility.GetNewCode();
        GLEntry."Document No." := LibraryUTUtility.GetNewCode();
        GLEntry."Transaction No." := SelectGLEntryTransactionNo();
        GLEntry.Insert();
    end;

    local procedure CreatePaymentGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; PaymentAmount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.", PaymentAmount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
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

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AppliesToID: Code[50]; VendorNo: Code[20]; PrintVendLedgerDetails: Boolean; AmountToApply: Decimal; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CreateVendorLedgerEntryWithGLEntry(VendorLedgerEntry, AppliesToID, VendorNo, AmountToApply, DocumentType);
        VendorLedgerEntry."Remaining Pmt. Disc. Possible" := LibraryRandom.RandDec(10, 2); // Using Random value less than Amount.
        VendorLedgerEntry."Pmt. Disc. Rcd.(LCY)" := LibraryRandom.RandDec(10, 2);
        VendorLedgerEntry."Pmt. Discount Date" := WorkDate();
        VendorLedgerEntry.Modify();

        LibraryVariableStorage.Enqueue(VendorLedgerEntry."Vendor No.");
        LibraryVariableStorage.Enqueue(PrintVendLedgerDetails);
    end;

    local procedure CreateDetailedVendorLedgerEntry(VendorLedgerEntryNo: Integer; TransactionNo: Integer): Integer
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntryNo;
        DetailedVendorLedgEntry."Entry Type" := DetailedVendorLedgEntry."Entry Type"::"Realized Loss";
        DetailedVendorLedgEntry.Amount := LibraryRandom.RandDecInDecimalRange(10, 20, 2);  // Using Random value more than Applied value.
        DetailedVendorLedgEntry."Amount (LCY)" := DetailedVendorLedgEntry.Amount;
        DetailedVendorLedgEntry."Transaction No." := TransactionNo;
        DetailedVendorLedgEntry.Insert(true);
        exit(DetailedVendorLedgEntry."Entry No.");
    end;

    local procedure CreateVendorLedgerEntryWithGLEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AppliesToID: Code[50]; VendorNo: Code[20]; AmountToApply: Decimal; DocumentType: Enum "Gen. Journal Document Type")
    var
        GLEntry: Record "G/L Entry";
    begin
        CreateGLEntry(GLEntry);
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Applies-to ID" := AppliesToID;
        VendorLedgerEntry."Amount to Apply" := AmountToApply;
        VendorLedgerEntry."External Document No." := LibraryUTUtility.GetNewCode();
        VendorLedgerEntry."Document Type" := DocumentType;
        VendorLedgerEntry."Transaction No." := GLEntry."Transaction No.";
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry."Closed by Entry No." := VendorLedgerEntry."Entry No.";
        VendorLedgerEntry.Insert();
    end;

    local procedure CreateVendorLedgerEntryWithCurrency(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AppliesToID: Code[50]; VendorNo: Code[20]; AmountToApply: Decimal; DocumentType: Enum "Gen. Journal Document Type"; CurrencyCode: Code[10])
    begin
        CreateVendorLedgerEntryWithGLEntry(VendorLedgerEntry, AppliesToID, VendorNo, AmountToApply, DocumentType);
        VendorLedgerEntry."Currency Code" := CurrencyCode;
        VendorLedgerEntry.Validate("Original Amount", AmountToApply);
        VendorLedgerEntry.Modify();
    end;

    local procedure CreateAndUpdateDetailedVendorLedgerEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.Get(CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", LibraryRandom.RandInt(10)));  // Using Random value for Transaction Number.
        DetailedVendorLedgEntry."Document No." := VendorLedgerEntry."Document No.";
        DetailedVendorLedgEntry."Document Type" := DetailedVendorLedgEntry."Document Type"::Invoice;
        DetailedVendorLedgEntry."Vendor No." := VendorLedgerEntry."Vendor No.";
        DetailedVendorLedgEntry."Entry Type" := EntryType;
        DetailedVendorLedgEntry.Modify();
    end;

    local procedure SelectGLEntryTransactionNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.FindLast();
        exit(GLEntry."Transaction No." + 1);
    end;

    local procedure CreateVendorWithPaymentTermsAndCurrency(CurrencyCode: Code[10]): Code[20]
    var
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
    begin
        LibraryERM.FindPaymentMethod(PaymentMethod);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateAndPostPurchaseInvoiceForVendorWithCurrency(VendorNo: Code[20]; CurrencyCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Payment Discount %", LibraryRandom.RandInt(10));
        PurchaseHeader.Validate("Pmt. Discount Date", LibraryRandom.RandDate(10));
        PurchaseHeader.Validate("Due Date", LibraryRandom.RandDateFromInRange(WorkDate(), 11, 20));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", '', 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(1000, 15000));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure GetPaymentDiscountAmountForeignCurrency(VendLedgEntryNo: Integer; DocNo: Code[20]): Decimal
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.LoadFields("Vendor Ledger Entry No.", "Entry Type", "Document Type", "Document No.", "Currency Code", Unapplied);
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntryNo);
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::"Payment Discount");
        DtldVendLedgEntry.SetRange("Document Type", DtldVendLedgEntry."Document Type"::Payment);
        DtldVendLedgEntry.SetRange("Document No.", DocNo);
        DtldVendLedgEntry.SetFilter("Currency Code", '<>%1', '');
        DtldVendLedgEntry.SetRange(Unapplied, false);
        if DtldVendLedgEntry.IsEmpty() then
            exit;

        DtldVendLedgEntry.CalcSums(Amount);
        exit(DtldVendLedgEntry.Amount);
    end;

    local procedure UnapplyVendLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendLedgerEntry);
    end;

    local procedure VerifyRemittanceAdviceJournalValues(DocumentNo: Code[35]; OriginalAmount: Decimal; PaidAmount: Decimal; CurrencyCode: Code[10])
    begin
        LibraryReportDataset.SetRange('AppliedVendLedgEntryTempExternalDocNo', DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists('AppliedVendLedgEntryTempOriginalAmt', OriginalAmount);
        LibraryReportDataset.AssertElementWithValueExists('AppliedVendLedgEntryTempRemainingAmt', 0);
        LibraryReportDataset.AssertElementWithValueExists('PaidAmount', PaidAmount);
        LibraryReportDataset.AssertElementWithValueExists('AppliedVendLedgEntryTempCurrCode', CurrencyCode);
    end;

    local procedure VerifyRemittanceAdviceJournalRemainingAndPaidAmounts(OriginalAmount: Decimal; PaidAmount: Decimal)
    begin
        LibraryReportDataset.AssertElementWithValueExists('AppliedVendLedgEntryTempRemainingAmt', OriginalAmount - PaidAmount);
        LibraryReportDataset.AssertElementWithValueExists('PaidAmount', PaidAmount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RemittanceAdviceJournalRequestPageHandler(var RemittanceAdviceJournal: TestRequestPage "Remittance Advice - Journal")
    var
        JournalTemplateName: Variant;
        JournalBatchName: Variant;
        No: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Remittance Advice - Journal";
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
        VendorNo: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Remittance Advice - Entries";
        LibraryVariableStorage.Dequeue(VendorNo);
        RemittanceAdviceEntries."Vendor Ledger Entry".SetFilter("Vendor No.", VendorNo);
        RemittanceAdviceEntries.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure RemittanceAdviceEntriesNoParamsRequestPageHandler(var RemittanceAdviceEntries: TestRequestPage "Remittance Advice - Entries")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreatePaymentWithPostingModalPageHandler(var CreatePayment: TestPage "Create Payment")
    var
        StartingDocumentNo: Text;
    begin
        StartingDocumentNo := LibraryVariableStorage.DequeueText();
        CreatePayment."Bank Account".SetValue(LibraryVariableStorage.DequeueText());
        CreatePayment."Posting Date".SetValue(LibraryVariableStorage.DequeueDate());
        CreatePayment."Starting Document No.".SetValue(StartingDocumentNo);
        CreatePayment.OK().Invoke();
    end;

    local procedure DeleteObjectOptionsIfNeeded()
    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
    begin
        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);
    end;
}

