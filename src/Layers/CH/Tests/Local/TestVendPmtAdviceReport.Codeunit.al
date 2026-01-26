codeunit 144029 "Test Vend. Pmt. Advice Report"
{
    // // [FEATURE] [Vendor Payment Advice]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        PmtProcessedMsg: Label 'Payment advice processed for 1 vendors.';
        MissingBankAccErr: Label 'Bank  does not exist for vendor %1.';
        RelatedPmtVendEntryNoTxt: Label 'EntryNo_PartPmtVendorEntry2';
        RelatedPmtVendDocTypeTxt: Label 'DocType_PartPmtVendorEntry2';
        RelatedPmtVendDocNoTxt: Label 'DocNo_PartPmtVendorEntry2';
        VendorNoTxt: Label 'No_Vendor';
        GenJnlLineNoTxt: Label 'LineNo_GenJnlLine';

    [Test]
    [HandlerFunctions('VendPmtAdviceReqPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure VendPmtAdviceExcludeESR()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        InvoiceGenJournalLine: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine1: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Responsible: Text;
        Advice: Text;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::"Post Payment Domestic");
        VendorBankAccount.Modify(true);
        PostPurchaseDocument(
          InvoiceGenJournalLine, InvoiceGenJournalLine."Document Type"::Invoice, Vendor, LibraryRandom.RandDec(1000, 2));
        CreateAppliedVendorPayment(GenJournalLine, InvoiceGenJournalLine, VendorBankAccount.Code);

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::ESR);
        VendorBankAccount.Modify(true);
        CreateAdditionalVendorPayment(GenJournalLine1, GenJournalLine, VendorBankAccount.Code);

        Responsible := CreateGuid();
        Advice := CreateGuid();

        // Exercise.
        Commit();
        RunVendPmtAdviceReport(GenJournalLine, false, Responsible, Advice);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData(GenJournalLine, -InvoiceGenJournalLine."Amount (LCY)", Responsible, Advice, 1);
    end;

    [Test]
    [HandlerFunctions('VendPmtAdviceReqPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure VendPmtAdviceExcludeESRUnappliedPmt()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        InvoiceGenJournalLine: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine1: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Responsible: Text;
        Advice: Text;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::"Post Payment Domestic");
        VendorBankAccount.Modify(true);
        PostPurchaseDocument(
          InvoiceGenJournalLine, InvoiceGenJournalLine."Document Type"::Invoice, Vendor, LibraryRandom.RandDec(1000, 2));
        CreateAppliedVendorPayment(GenJournalLine, InvoiceGenJournalLine, VendorBankAccount.Code);
        CreateAdditionalVendorPayment(GenJournalLine1, GenJournalLine, VendorBankAccount.Code);

        Responsible := CreateGuid();
        Advice := CreateGuid();

        // Exercise.
        Commit();
        RunVendPmtAdviceReport(GenJournalLine, false, Responsible, Advice);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData(GenJournalLine, -InvoiceGenJournalLine."Amount (LCY)", Responsible, Advice, 2);
        VerifyReportData(GenJournalLine1, 0, Responsible, Advice, 2);
    end;

    [Test]
    [HandlerFunctions('VendPmtAdviceReqPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure VendPmtAdviceIncludeESR()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        InvoiceGenJournalLine: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Responsible: Text;
        Advice: Text;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::"Post Payment Domestic");
        VendorBankAccount.Modify(true);
        PostPurchaseDocument(
          InvoiceGenJournalLine, InvoiceGenJournalLine."Document Type"::Invoice, Vendor, LibraryRandom.RandDec(1000, 2));
        CreateAppliedVendorPayment(GenJournalLine, InvoiceGenJournalLine, VendorBankAccount.Code);
        Responsible := CreateGuid();
        Advice := CreateGuid();

        // Exercise.
        Commit();
        RunVendPmtAdviceReport(GenJournalLine, true, Responsible, Advice);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData(GenJournalLine, -InvoiceGenJournalLine."Amount (LCY)", Responsible, Advice, 1);
    end;

    [Test]
    [HandlerFunctions('VendPmtAdviceReqPageHandler')]
    [Scope('OnPrem')]
    procedure VendPmtAdviceMissingBankAccount()
    var
        InvoiceGenJournalLine: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        PostPurchaseDocument(
          InvoiceGenJournalLine, InvoiceGenJournalLine."Document Type"::Invoice, Vendor, LibraryRandom.RandDec(1000, 2));
        CreateAppliedVendorPayment(GenJournalLine, InvoiceGenJournalLine, '');

        // Exercise.
        Commit();
        asserterror RunVendPmtAdviceReport(GenJournalLine, false, '', '');

        // Verify.
        Assert.ExpectedError(StrSubstNo(MissingBankAccErr, Vendor."No."));
    end;

    [Test]
    [HandlerFunctions('VendPmtAdviceReqPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure VendPmtAppliedToMultipleEntries()
    var
        Vendor: Record Vendor;
        GenJnlLine: Record "Gen. Journal Line";
        PmtGenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CrMemoNo: array[2] of Code[20];
        InvAmount: Decimal;
        CrMemoAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Application]
        // [SCENARIO 375785] Credit Memo applied to Invoice indirectly in chain with multiple entries should be printed in Vendor Payment Advice Report

        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Invoice "A1" with amount = 100
        InvAmount := LibraryRandom.RandDec(1000, 2);
        PostPurchaseDocument(GenJnlLine, GenJnlLine."Document Type"::Invoice, Vendor, InvAmount);

        // [GIVEN] Credit Memo "B1" with amount -50 and Credit Memo "B2" with amount -70 applied to invoice "A1"
        CrMemoAmount[1] := Round(InvAmount / LibraryRandom.RandIntInRange(3, 10));
        CrMemoAmount[2] := InvAmount - CrMemoAmount[1] + LibraryRandom.RandDec(100, 2);
        CrMemoNo[1] := PostApplyCreditMemo(Vendor, CrMemoAmount[1], GenJnlLine."Document No.");
        CrMemoNo[2] := PostApplyCreditMemo(Vendor, CrMemoAmount[2], GenJnlLine."Document No.");

        // [GIVEN] Invoice "A2" with amount 60 applied to Credit Memo "B2" with remaining amount = -20
        PostPurchaseDocument(
          GenJnlLine, GenJnlLine."Document Type"::Invoice, Vendor, CrMemoAmount[2] + LibraryRandom.RandDec(100, 2));
        LibraryERM.ApplyVendorLedgerEntries(
          VendLedgEntry."Document Type"::Invoice, VendLedgEntry."Document Type"::"Credit Memo", GenJnlLine."Document No.", CrMemoNo[2]);

        // [GIVEN] Payment Journal Line with amount -40 applied to Invoice "A2" so that all entries are closed
        CreateAppliedVendorPaymentWithAmount(PmtGenJnlLine, GenJnlLine);
        Commit();

        // [WHEN] Run Vendor Payment Advice Report
        RunVendPmtAdviceReport(PmtGenJnlLine, true, '', '');

        // [THEN] Credit Memo "B1" printed in Vendor Payment Advice Report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(VendorNoTxt, Vendor."No.");
        LibraryReportDataset.SetRange(GenJnlLineNoTxt, PmtGenJnlLine."Line No.");
        LibraryReportDataset.MoveToRow(3); // 1 - invoice "A1"; 2 - invoice "A2"
        LibraryReportDataset.AssertCurrentRowValueEquals(
          RelatedPmtVendDocTypeTxt, Format(VendLedgEntry."Document Type"::"Credit Memo", 0));
        LibraryReportDataset.AssertCurrentRowValueEquals(RelatedPmtVendDocNoTxt, CrMemoNo[1]);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          RelatedPmtVendEntryNoTxt, GetVendLedgEntryNo(VendLedgEntry."Document Type"::"Credit Memo", CrMemoNo[1]));
    end;

    [Test]
    [HandlerFunctions('VendPmtAdviceNoActionReqPageHandler')]
    [Scope('OnPrem')]
    procedure RunVendPmtAdviceReportFromPmtJournalInSaaS()
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 408605] Stan can run the "SR Vendor Payment Advice" report from the "Payment Journal" page

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal."&Print Payment Ad&vice".Invoke();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure PostPurchaseDocument(var GenJournalLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; Vendor: Record Vendor; Amount: Decimal): Code[20]
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, DocType, GenJournalLine."Account Type"::Vendor, Vendor."No.", -Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAppliedVendorPayment(var GenJournalLine: Record "Gen. Journal Line"; InvGenJournalLine: Record "Gen. Journal Line"; VendorBankAccountNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
          InvGenJournalLine."Account No.", -InvGenJournalLine."Amount (LCY)");
        GenJournalLine.Validate("Applies-to Doc. Type", InvGenJournalLine."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", InvGenJournalLine."Document No.");
        GenJournalLine.Validate("Recipient Bank Account", VendorBankAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAppliedVendorPaymentWithAmount(var PmtGenJnlLine: Record "Gen. Journal Line"; GenJnlLine: Record "Gen. Journal Line")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        CreateAppliedVendorPayment(PmtGenJnlLine, GenJnlLine, '');
        PmtGenJnlLine.Validate(
          Amount, GetVendLedgEntryRemAmount(VendLedgEntry, VendLedgEntry."Document Type"::Invoice, GenJnlLine."Document No."));
        PmtGenJnlLine.Modify(true);
    end;

    local procedure CreateAdditionalVendorPayment(var GenJournalLine1: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line"; VendorBankAccountNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine1,
          GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine1."Document Type"::Payment, GenJournalLine1."Account Type"::Vendor, GenJournalLine."Account No.",
          GenJournalLine1."Bal. Account Type"::"G/L Account", '', GenJournalLine."Amount (LCY)");
        GenJournalLine1.Validate("Recipient Bank Account", VendorBankAccountNo);
        GenJournalLine1.Modify(true);
    end;

    local procedure PostApplyCreditMemo(Vendor: Record Vendor; EntryAmount: Decimal; InvNo: Code[20]) DocNo: Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        DocNo :=
          PostPurchaseDocument(GenJnlLine, GenJnlLine."Document Type"::"Credit Memo", Vendor, -EntryAmount);
        LibraryERM.ApplyVendorLedgerEntries(
          VendLedgEntry."Document Type"::Invoice, VendLedgEntry."Document Type"::"Credit Memo", InvNo, DocNo);
    end;

    local procedure GetVendLedgEntryRemAmount(var VendLedgEntry: Record "Vendor Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]): Decimal
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, DocType, DocNo);
        VendLedgEntry.CalcFields("Remaining Amount");
        exit(VendLedgEntry."Remaining Amount");
    end;

    local procedure GetVendLedgEntryNo(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]): Integer
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, DocType, DocNo);
        exit(VendLedgEntry."Entry No.");
    end;

    local procedure RunVendPmtAdviceReport(GenJournalLine: Record "Gen. Journal Line"; ShowESR: Boolean; Responsible: Text; Advice: Text)
    var
        Vendor: Record Vendor;
        SRVendorPaymentAdvice: Report "SR Vendor Payment Advice";
    begin
        LibraryVariableStorage.Enqueue(ShowESR);
        LibraryVariableStorage.Enqueue(Responsible);
        LibraryVariableStorage.Enqueue(Advice);
        SRVendorPaymentAdvice.DefineJourBatch(GenJournalLine);
        Vendor.SetRange("No.", GenJournalLine."Account No.");
        SRVendorPaymentAdvice.SetTableView(Vendor);
        SRVendorPaymentAdvice.RunModal();
    end;

    local procedure VerifyReportData(GenJournalLine: Record "Gen. Journal Line"; AppliedAmount: Decimal; Responsible: Text; Advice: Text; ExpCount: Integer)
    begin
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('No_Vendor', GenJournalLine."Account No.");
        Assert.AreEqual(ExpCount, LibraryReportDataset.RowCount(), 'Incorrect number of payment lines in the report.');
        LibraryReportDataset.SetRange('LineNo_GenJnlLine', GenJournalLine."Line No.");
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should only be one line per journal line in the report.');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('VendEntryDocNo', GenJournalLine."Applies-to Doc. No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('VendEntryAmount', AppliedAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount_GenJnlLine', GenJournalLine."Amount (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('RespPerson', Responsible);
        LibraryReportDataset.AssertCurrentRowValueEquals('MsgTxt', Advice);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendPmtAdviceReqPageHandler(var SRVendorPaymentAdvice: TestRequestPage "SR Vendor Payment Advice")
    var
        ShowESRPayments: Variant;
        Responsible: Variant;
        Advice: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowESRPayments);
        LibraryVariableStorage.Dequeue(Responsible);
        LibraryVariableStorage.Dequeue(Advice);
        SRVendorPaymentAdvice.ShowEsrPayments.SetValue(ShowESRPayments);
        SRVendorPaymentAdvice.RespPerson.SetValue(Responsible);
        SRVendorPaymentAdvice.MsgTxt.SetValue(Advice);
        SRVendorPaymentAdvice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendPmtAdviceNoActionReqPageHandler(var SRVendorPaymentAdvice: TestRequestPage "SR Vendor Payment Advice")
    begin
        SRVendorPaymentAdvice.Cancel().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, PmtProcessedMsg) > 0, 'Unexpected message:' + Message);
    end;
}

