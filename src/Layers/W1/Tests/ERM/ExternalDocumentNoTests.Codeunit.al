codeunit 134345 "External Document No. Tests"
{
    Permissions = TableData "Vendor Ledger Entry" = ri,
                  TableData "Purchases & Payables Setup" = rm;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [External Document No.]
    end;

    var
        PurchInvAlreadyExistErr: Label 'Purchase Invoice %1 already exists for this vendor.', Comment = '%1 = purchase invoice no.';
        PurchInvExistsInRepErr: Label 'Purchase Invoice %1 already exists.', Comment = '%1 = external document no.';
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ReversedEntryDoesNotConsiderBySetFilterForExternalDocNoFunction()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorMgt: Codeunit "Vendor Mgt.";
        VendNo: Code[20];
        ExtDocNo: Text;
        EntryNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 295702] A reversed Vendor Ledger Entry does not consider when calling function SetFilterForExternalDocNoFunction

        Initialize();
        VendNo := LibraryPurchase.CreateVendorNo();
        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength());
        EntryNo := MockVendorLedgerEntry(VendNo, WorkDate(), ExtDocNo, false);
        MockVendorLedgerEntry(VendNo, WorkDate(), ExtDocNo, true);
        VendorMgt.SetFilterForExternalDocNo(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, CopyStr(ExtDocNo, 1, 35), VendNo, WorkDate());
        Assert.RecordCount(VendorLedgerEntry, 1);
        VendorLedgerEntry.FindFirst();
        Assert.AreEqual(EntryNo, VendorLedgerEntry."Entry No.", 'Incorrect entry no.');
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalTestDoesNotConsiderReversedEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendNo: Code[20];
        ExtDocNo: Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 295702] A "General Journal -Test" report runs successfully if there is duplicated External Document No. in reversed Vendor Ledger Entry

        Initialize();

        // [GIVEN] Vendor Ledger Entry with Reversed enabled, "External Document No." = "X" and "Document Date" = 01.01.2019
        VendNo := LibraryPurchase.CreateVendorNo();
        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength());
        MockVendorLedgerEntry(VendNo, WorkDate(), ExtDocNo, true);

        // [GIVEN] General Journal Line with "External Document No." = "X" and "Document Date" = 01.01.2020
        CreateGenJnlLineInNextFY(GenJournalLine, VendNo, 1, ExtDocNo);
        Commit();
        GenJournalLine.SetRecFilter();

        // [WHEN] Run "General Journal - Test" report against General Journal Line
        REPORT.Run(REPORT::"General Journal - Test", true, false, GenJournalLine);

        // [THEN] No error "Purchase Invoice X already exists." prints
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueNotExist(
          'ErrorTextNumber', StrSubstNo(PurchInvExistsInRepErr, UpperCase(ExtDocNo)));
    end;

    [Test]
    [HandlerFunctions('VendorPrepaymentJnlRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorPrepaymentJnlDoesNotConsiderReversedEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendNo: Code[20];
        ExtDocNo: Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 295702] A "Vendor Pre-Payment Journal" report runs successfully if there is duplicated External Document No. in reversed Vendor Ledger Entry

        Initialize();

        // [GIVEN] Vendor Ledger Entry with Reversed enabled, "External Document No." = "X" and "Document Date" = 01.01.2019
        VendNo := LibraryPurchase.CreateVendorNo();
        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength());
        MockVendorLedgerEntry(VendNo, WorkDate(), ExtDocNo, true);

        // [GIVEN] General Journal Line with "External Document No." = "X" and "Document Date" = 01.01.2020
        CreateGenJnlLineInNextFY(GenJournalLine, VendNo, -1, ExtDocNo);
        Commit();
        GenJournalLine.SetRecFilter();

        // [WHEN] Run "Vendor Pre-Payment Journal" report against General Journal Line
        RunVendorPrepaymentJnl(GenJournalLine);

        // [THEN] No error "Purchase Invoice X already exists." prints
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueNotExist(
          'ErrorText_Number_', StrSubstNo(PurchInvExistsInRepErr, UpperCase(ExtDocNo)));
    end;

    [Test]
    [HandlerFunctions('PurchDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchDocumentTestDoesNotConsiderReversedEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        VendNo: Code[20];
        LineGLAccountNo: Code[20];
        ExtDocNo: Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 295702] A "Purchase Document - Test" report runs successfully if there is duplicated External Document No. in reversed Vendor Ledger Entry

        Initialize();

        // [GIVEN] Vendor Ledger Entry with Reversed enabled and "External Document No." = "X" and "Document Date" = 01.01.2019
        CreatePrepmtVendor(VendNo, LineGLAccountNo);
        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength());
        MockVendorLedgerEntry(VendNo, WorkDate(), ExtDocNo, true);

        // [GIVEN] Purchase Invoice with "External Document No." = "X" and "Document Date" = 01.01.2020
        CreatePurchDocInNextFY(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo, LineGLAccountNo, ExtDocNo, 0);
        Commit();
        PurchaseHeader.SetRecFilter();

        // [WHEN] Run "Purchase Document - Test" report against Purchase Invoice
        REPORT.Run(REPORT::"Purchase Document - Test", true, false, PurchaseHeader);

        // [THEN] No error "Purchase Invoice X already exists." prints
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueNotExist(
          'ErrorText_Number_', StrSubstNo(PurchInvAlreadyExistErr, UpperCase(ExtDocNo)));
    end;

    [Test]
    [HandlerFunctions('PurchDocumentPrepmtTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchDocumentPrepmtDoesNotConsiderReversedEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        VendNo: Code[20];
        LineGLAccountNo: Code[20];
        ExtDocNo: Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 295702] A "Purchase Prepmt. Doc. - Test" report runs successfully if there is duplicated External Document No. in reversed Vendor Ledger Entry

        Initialize();

        // [GIVEN] Vendor Ledger Entry with Reversed enabled and "External Document No." = "X" and "Document Date" = 01.01.2019
        CreatePrepmtVendor(VendNo, LineGLAccountNo);
        ExtDocNo := LibraryUtility.GenerateRandomText(GetExtDocNoLength());
        MockVendorLedgerEntry(VendNo, WorkDate(), ExtDocNo, true);

        // [GIVEN] Purchase Prepayment Order with "External Document No." = "X" and "Document Date" = 01.01.2020
        CreatePurchDocInNextFY(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, VendNo, LineGLAccountNo, ExtDocNo, LibraryRandom.RandDec(50, 2));
        Commit();
        PurchaseHeader.SetRecFilter();

        // [WHEN] Run "Purchase Prepmt. Doc. - Test" report against Purchase Invoice
        REPORT.Run(REPORT::"Purchase Prepmt. Doc. - Test", true, false, PurchaseHeader);

        // [THEN] No error "Purchase Invoice X already exists." prints
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueNotExist(
          'ErrorText_Number_', StrSubstNo(PurchInvAlreadyExistErr, UpperCase(ExtDocNo)));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"External Document No. Tests");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"External Document No. Tests");
        BindSubscription(LibraryJobQueue);
        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"External Document No. Tests");
    end;

    local procedure GetExtDocNoLength(): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        exit(MaxStrLen(VendorLedgerEntry."External Document No."));
    end;

    local procedure MockVendorLedgerEntry(VendNo: Code[20]; DocumentDate: Date; ExtDocNo: Text; Reversed: Boolean): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Document Date" := DocumentDate;
        VendorLedgerEntry."Vendor No." := VendNo;
        VendorLedgerEntry."External Document No." :=
          CopyStr(ExtDocNo, 1, MaxStrLen(VendorLedgerEntry."External Document No."));
        VendorLedgerEntry.Reversed := Reversed;
        VendorLedgerEntry.Insert();
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure CreatePrepmtVendor(var VendNo: Code[20]; var LineGLAccountNo: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        LineGLAccount: Record "G/L Account";
    begin
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LineGLAccountNo := LineGLAccount."No.";
        VendNo :=
          LibraryPurchase.CreateVendorWithBusPostingGroups(
            LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
    end;

    local procedure CreateGenJnlLineInNextFY(var GenJournalLine: Record "Gen. Journal Line"; VendNo: Code[20]; Sign: Integer; ExtDocNo: Text)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, VendNo, Sign * LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Posting Date", CalcDate('<1Y>', WorkDate()));
        GenJournalLine.Validate("External Document No.",
          CopyStr(ExtDocNo, 1, MaxStrLen(GenJournalLine."External Document No.")));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePurchDocInNextFY(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; VendNo: Code[20]; GLAccNo: Code[20]; ExtDocNo: Text; PrepmtPct: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, VendNo);
        PurchaseHeader.Validate("Posting Date", CalcDate('<1Y>', WorkDate()));
        PurchaseHeader.Validate("Vendor Invoice No.",
          CopyStr(ExtDocNo, 1, MaxStrLen(PurchaseHeader."Vendor Invoice No.")));
        PurchaseHeader.Validate("Prepayment %", PrepmtPct);
        PurchaseHeader.Validate("Tax Area Code", '');
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          GLAccNo, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure RunVendorPrepaymentJnl(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorPrePaymentJournal: Report "Vendor Pre-Payment Journal";
    begin
        GenJournalBatch.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalBatch.SetRange(Name, GenJournalLine."Journal Batch Name");
        Clear(VendorPrePaymentJournal);
        VendorPrePaymentJournal.SetTableView(GenJournalBatch);
        VendorPrePaymentJournal.SetTableView(GenJournalLine);
        VendorPrePaymentJournal.RunModal();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTestRequestPageHandler(var GeneralJournalTest: TestRequestPage "General Journal - Test")
    begin
        GeneralJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorPrepaymentJnlRequestPageHandler(var VendorPrepaymentJnl: TestRequestPage "Vendor Pre-Payment Journal")
    begin
        VendorPrepaymentJnl.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchDocumentTestRequestPageHandler(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    begin
        PurchaseDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchDocumentPrepmtTestRequestPageHandler(var PurchasePrepmtDocTest: TestRequestPage "Purchase Prepmt. Doc. - Test")
    begin
        PurchasePrepmtDocTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

