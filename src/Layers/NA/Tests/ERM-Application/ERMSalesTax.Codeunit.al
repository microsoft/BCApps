codeunit 134388 "ERM Sales Tax"
{
    Permissions = TableData "VAT Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax]
        Initialize();
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        TaxDetailErr: Label 'Tax Detail not found.';

    [Test]
    [Scope('OnPrem')]
    procedure SalesTax()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        // Test VAT Posting Setup with Sales Tax.

        // Setup: Create new VAT Posting Setup.
        Initialize();
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);

        // Exercise.
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Modify(true);

        // Verify: Verify VAT Posting Setup with Sales Tax Exists.
        VATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.TestField("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesTaxGroup()
    var
        TaxGroup: Record "Tax Group";
    begin
        // Test creation of Sales Tax Group.

        // Setup.
        Initialize();

        // Exercise.
        LibraryERM.CreateTaxGroup(TaxGroup);

        // Verify: Verify created Tax Group exists.
        TaxGroup.Get(TaxGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesTaxJurisdiction()
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        JurisdictionCode: Code[10];
    begin
        // Test creation of Sales Tax Jurisdiction.

        // Setup.
        Initialize();

        // Exercise.
        JurisdictionCode := CreateSalesTaxJurisdiction();

        // Verify: Verify created Tax Jurisdiction exists.
        TaxJurisdiction.Get(JurisdictionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesTaxDetail()
    var
        TaxDetail: Record "Tax Detail";
    begin
        // Test creation of Sales Tax Detail.

        // Setup.
        Initialize();

        // Exercise.
        CreateSalesTaxDetail(TaxDetail);

        // Verify: Verify created Tax Detail exists.
        VerifyTaxDetail(TaxDetail);
    end;

    [Test]
    [HandlerFunctions('SalesTaxesCollectedReqPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesTaxesCollectedReport()
    var
        TaxDetail: array[3] of Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        VATEntry: array[4] of Record "VAT Entry";
    begin
        // [SCENARIO 287174] Sales Taxes Collected report clears tax amounts in dataset for each new Tax Jurisdiction and VAT Entry
        Initialize();

        // [GIVEN] VAT Entry for Tax Jurisdiction "A" with Base = 110, Amount = 10
        CreateSalesTaxDetail(TaxDetail[1]);
        MockVATEntry(VATEntry[1], TaxDetail[1], LibraryRandom.RandDecInRange(100, 200, 2), true);
        // [GIVEN] No VAT Entries for Tax Jurisdiction "B"
        CreateSalesTaxDetail(TaxDetail[2]);
        // [GIVEN] VAT Entry for Tax Jurisdiction "C" with Base = 210, Amount = 10
        // [GIVEN] VAT Entry for Tax Jurisdiction "C" with Base = 220, Amount = 0, Tax Liable = Yes
        // [GIVEN] VAT Entry for Tax Jurisdiction "C" with Base = 230, Amount = 0, Tax Liable = No
        CreateSalesTaxDetail(TaxDetail[3]);
        MockVATEntry(VATEntry[2], TaxDetail[3], LibraryRandom.RandDecInRange(100, 200, 2), true);
        MockVATEntry(VATEntry[3], TaxDetail[3], 0, true);
        MockVATEntry(VATEntry[4], TaxDetail[3], 0, false);

        TaxJurisdiction.SetFilter(
          Code, '%1|%2|%3',
          TaxDetail[1]."Tax Jurisdiction Code", TaxDetail[2]."Tax Jurisdiction Code", TaxDetail[3]."Tax Jurisdiction Code");

        // [WHEN] Run Sales Taxes Collected report
        REPORT.Run(REPORT::"Sales Taxes Collected", true, false, TaxJurisdiction);

        // [THEN] Dataset for Tax Jurisdiction "A": 'SalesTaxAmt' = 10, 'TaxableSalesAmt' = 110, 'NonTaxableSalesAmt' = 0, 'ExemptSalesAmt' = 0
        LibraryReportDataset.LoadDataSetFile();
        VerifyTaxAmountsInSalesTaxesCollectedReport(
          TaxDetail[1]."Tax Jurisdiction Code", -VATEntry[1].Amount, -VATEntry[1].Base, 0, 0, 1);
        // [THEN] Dataset line for Tax Jurisdiction "B" has 'SalesTaxAmt' = 0,
        // [THEN] 'TaxableSalesAmt', 'NonTaxableSalesAmt','ExemptSalesAmt' are not exported
        VerifyEmptyTaxJurisdictionInSalesTaxesCollectedReport(TaxDetail[2]."Tax Jurisdiction Code");
        // [THEN] 3 lines in dataset for Tax Jurisdiction "C":
        // [THEN] 'SalesTaxAmt' = 10, 'TaxableSalesAmt' = 210, 'NonTaxableSalesAmt' = 0, 'ExemptSalesAmt' = 0
        VerifyTaxAmountsInSalesTaxesCollectedReport(
          TaxDetail[3]."Tax Jurisdiction Code", -VATEntry[2].Amount, -VATEntry[2].Base, 0, 0, 1);
        // [THEN] 'SalesTaxAmt' = 0, 'TaxableSalesAmt' = 0, 'NonTaxableSalesAmt' = 220, 'ExemptSalesAmt' = 0
        VerifyTaxAmountsInSalesTaxesCollectedReport(
          TaxDetail[3]."Tax Jurisdiction Code", 0, 0, -VATEntry[3].Base, 0, 2);
        // [THEN] 'SalesTaxAmt' = 0, 'TaxableSalesAmt' = 0, 'NonTaxableSalesAmt' = 0, 'ExemptSalesAmt' = 0=230
        VerifyTaxAmountsInSalesTaxesCollectedReport(
          TaxDetail[3]."Tax Jurisdiction Code", 0, 0, 0, -VATEntry[4].Base, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTaxSetupWithNonTaxableGroup()
    var
        TaxSetup: Record "Tax Setup";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
        TaxDetail: Record "Tax Detail";
    begin
        // [FEATURE] [UT] [Tax Detail]
        // [SCENARIO 378632] ValidateTaxSetup with Non-Taxable Group Code
        Initialize();

        // [GIVEN] Tax Detail line for Tax Jurisdiction with Tax Group = blank
        TaxSetup.Get();
        CreateTaxJurisditionWithTaxArea(TaxJurisdiction, TaxArea);
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, '', TaxDetail."Tax Type"::"Sales and Use Tax", 0D);

        // [GIVEN] Set up "Non-Taxable Tax Group Code" = "NT" in Tax Setup
        LibraryERM.CreateTaxGroup(TaxGroup);
        UpdateTaxSetupWithNonTaxGroup(TaxGroup.Code);

        // [WHEN] Run ValidateTaxSetup for "NT" Tax Group
        TaxDetail.ValidateTaxSetup(TaxArea.Code, TaxGroup.Code, 0D);

        // [THEN] Tax Detail line is created for "NT" Tax Group
        TaxDetail.Reset();
        TaxDetail.SetRange("Tax Jurisdiction Code", TaxJurisdiction.Code);
        TaxDetail.SetRange("Tax Group Code", TaxGroup.Code);
        Assert.RecordIsNotEmpty(TaxDetail);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTaxSetupWithNewTaxGroupWhenBlankTaxDetailExists()
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
        TaxDetail: Record "Tax Detail";
    begin
        // [FEATURE] [UT] [Tax Detail]
        // [SCENARIO 378632] ValidateTaxSetup with new Tax Group when Tax Detail with blank Tax Group exists
        Initialize();

        // [GIVEN] Tax Detail line for Tax Jurisdiction with Tax Group = blank
        CreateTaxJurisditionWithTaxArea(TaxJurisdiction, TaxArea);
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, '', TaxDetail."Tax Type"::"Sales and Use Tax", 0D);

        // [GIVEN] Set up "Non-Taxable Tax Group Code" = "NT" in Tax Setup
        LibraryERM.CreateTaxGroup(TaxGroup);
        UpdateTaxSetupWithNonTaxGroup(TaxGroup.Code);

        // [GIVEN] Tax Group "Gr"
        LibraryERM.CreateTaxGroup(TaxGroup);

        // [WHEN] Run ValidateTaxSetup for "Gr" Tax Group
        TaxDetail.ValidateTaxSetup(TaxArea.Code, TaxGroup.Code, 0D);

        // [THEN] No new Tax Detail line created for "Gr" Tax Group
        TaxDetail.Reset();
        TaxDetail.SetRange("Tax Jurisdiction Code", TaxJurisdiction.Code);
        TaxDetail.SetRange("Tax Group Code", TaxGroup.Code);
        Assert.RecordIsEmpty(TaxDetail);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateTaxSetupWithNewTaxGroupWhenNoBlankTaxDetailExists()
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
        TaxDetail: Record "Tax Detail";
    begin
        // [FEATURE] [UT] [Tax Detail]
        // [SCENARIO 378632] ValidateTaxSetup with new Tax Group when no Tax Detail with blank Tax Group
        Initialize();

        // [GIVEN] Tax Jurisdiction with Tax Area Line
        CreateTaxJurisditionWithTaxArea(TaxJurisdiction, TaxArea);
        TaxDetail.SetRange("Tax Jurisdiction Code", TaxJurisdiction.Code);
        TaxDetail.DeleteAll();

        // [GIVEN] Set up "Non-Taxable Tax Group Code" = "NT" in Tax Setup with Tax Detail Line
        LibraryERM.CreateTaxGroup(TaxGroup);
        UpdateTaxSetupWithNonTaxGroup(TaxGroup.Code);
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroup.Code, TaxDetail."Tax Type"::"Sales and Use Tax", 0D);

        // [GIVEN] Tax Group "Gr"
        LibraryERM.CreateTaxGroup(TaxGroup);

        // [WHEN] Run ValidateTaxSetup for "Gr" Tax Group
        TaxDetail.ValidateTaxSetup(TaxArea.Code, TaxGroup.Code, 0D);

        // [THEN] New Tax Detail line is created for "Gr" Tax Group
        TaxDetail.Reset();
        TaxDetail.SetRange("Tax Jurisdiction Code", TaxJurisdiction.Code);
        TaxDetail.SetRange("Tax Group Code", TaxGroup.Code);
        Assert.RecordIsNotEmpty(TaxDetail);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesTaxJournalSkipsReservedConcurrentNumbers()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLTransaction: Record "G/L Transaction";
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        VATEntry: Record "VAT Entry";
        ReservedVATEntryNo: Integer;
        ReservedTransactionNo: Integer;
    begin
        // [FEATURE] [Sales Tax] [Concurrent Posting]
        // [SCENARIO] Sales tax journal posting skips VAT entry and transaction numbers reserved by another allocation.
        Initialize();

        // [GIVEN] Concurrent posting is enabled.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Use Concurrent Posting", true);
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] VAT entry and transaction numbers have been reserved without inserting entries.
        ReservedVATEntryNo := VATEntry.GetNextEntryNo();
        ReservedTransactionNo := GLTransaction.GetNextTransactionNo();

        // [WHEN] The sales tax journal is posted through the general-journal posting engine.
        PostSalesTaxJournalVATEntry(VATEntry);

        // [THEN] Neither reserved number is reused, and the journal amount is retained.
        Assert.IsTrue(VATEntry."Entry No." > ReservedVATEntryNo, 'The reserved VAT entry number must not be reused.');
        Assert.IsTrue(VATEntry."Transaction No." > ReservedTransactionNo, 'The reserved transaction number must not be reused.');
        VATEntry.TestField(Amount, 100);

        // [THEN] The VAT entry belongs to the same transaction and register as the balanced G/L entries.
        VATEntry.TestField("G/L Register No.");
        GLTransaction.Get(VATEntry."Transaction No.");
        GLTransaction.TestField("G/L Register No.", VATEntry."G/L Register No.");
        GLRegister.Get(VATEntry."G/L Register No.");
        GLRegister.TestField("Source Code", VATEntry."Source Code");
        Assert.IsTrue(
            (GLRegister."From VAT Entry No." <= VATEntry."Entry No.") and
            (GLRegister."To VAT Entry No." >= VATEntry."Entry No."),
            'The posting register must include the sales tax VAT entry.');
        GLEntry.SetRange("Transaction No.", VATEntry."Transaction No.");
        Assert.AreEqual(2, GLEntry.Count(), 'The sales tax transaction must contain the journal and balancing entries.');
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, 0);
        GLEntry.FindFirst();
        GLEntry.TestField("G/L Register No.", VATEntry."G/L Register No.");
        GLEntryVATEntryLink.Get(GLEntry."Entry No.", VATEntry."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesTaxJournalUsesLegacyNumbers()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        ExpectedVATEntryNo: Integer;
        ExpectedTransactionNo: Integer;
    begin
        // [FEATURE] [Sales Tax] [Concurrent Posting]
        // [SCENARIO] Sales tax journal posting retains tail-based numbering when concurrent posting is disabled.
        Initialize();

        // [GIVEN] Concurrent posting is disabled.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Use Concurrent Posting", false);
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] The last persisted VAT entry and G/L transaction numbers.
        ExpectedVATEntryNo := 1;
        if VATEntry.FindLast() then
            ExpectedVATEntryNo := VATEntry."Entry No." + 1;
        ExpectedTransactionNo := 1;
        if GLEntry.FindLast() then
            ExpectedTransactionNo := GLEntry."Transaction No." + 1;

        // [WHEN] The sales tax journal creates its VAT entry.
        VATEntry.Reset();
        PostSalesTaxJournalVATEntry(VATEntry);

        // [THEN] The entry uses the next numbers after the persisted tails.
        VATEntry.TestField("Entry No.", ExpectedVATEntryNo);
        VATEntry.TestField("Transaction No.", ExpectedTransactionNo);
        VATEntry.TestField(Amount, 100);
    end;

    local procedure PostSalesTaxJournalVATEntry(var VATEntry: Record "VAT Entry")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ManageSalesTaxJournal: Codeunit "Manage Sales Tax Journal";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        LastVATEntryNo: Integer;
        PostingDate: Date;
    begin
        VATEntry.Reset();
        if VATEntry.FindLast() then
            LastVATEntryNo := VATEntry."Entry No.";

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 100);

        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        ManageSalesTaxJournal.PostToVAT(GenJournalLine);
        PostingDate := GenJournalLine."Posting Date";

        VATEntry.SetFilter("Entry No.", '>%1', LastVATEntryNo);
        VATEntry.SetRange("Document No.", GenJournalLine."Document No.");
        if GeneralLedgerSetup.UseConcurrentPosting() then begin
            Assert.RecordIsEmpty(VATEntry);
            ManageSalesTaxJournal.CreateGenJnlLines(GenJournalLine);
            BindSubscription(ManageSalesTaxJournal);
            GenJnlPostBatch.SetSuppressCommit(true);
            GenJnlPostBatch.Run(GenJournalLine);
            UnbindSubscription(ManageSalesTaxJournal);
        end;
        VATEntry.FindFirst();
        VATEntry.TestField("Posting Date", PostingDate);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Tax");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Tax");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Tax");
    end;

    local procedure CreateSalesTaxJurisdiction(): Code[10]
    var
        GLAccount: Record "G/L Account";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
        GLAccount.Modify();
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccount."No.");
        TaxJurisdiction.Validate("Tax Account (Purchases)", GLAccount."No.");
        TaxJurisdiction.Validate("Reverse Charge (Purchases)", GLAccount."No.");
        TaxJurisdiction.Validate("Report-to Jurisdiction", TaxJurisdiction.Code);
        TaxJurisdiction.Validate("Calculate Tax on Tax", true);
        TaxJurisdiction.Modify(true);
        exit(TaxJurisdiction.Code);
    end;

    local procedure CreateSalesTaxDetail(var TaxDetail: Record "Tax Detail")
    var
        TaxGroup: Record "Tax Group";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(TaxDetail, CreateSalesTaxJurisdiction(), TaxGroup.Code, TaxDetail."Tax Type"::"Sales Tax Only", WorkDate());
    end;

    local procedure CreateTaxJurisditionWithTaxArea(var TaxJurisdiction: Record "Tax Jurisdiction"; var TaxArea: Record "Tax Area")
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxJurisdiction.Code);
    end;

    local procedure MockVATEntry(var VATEntry: Record "VAT Entry"; TaxDetail: Record "Tax Detail"; TaxAmount: Decimal; TaxLiable: Boolean)
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry."Posting Date" := WorkDate();
        VATEntry."VAT Reporting Date" := WorkDate();
        VATEntry."Tax Type" := VATEntry."Tax Type"::"Sales Tax Only";
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Tax Group Code" := TaxDetail."Tax Group Code";
        VATEntry."Tax Jurisdiction Code" := TaxDetail."Tax Jurisdiction Code";
        VATEntry."Tax Liable" := TaxLiable;
        VATEntry.Base := LibraryRandom.RandDecInRange(100, 200, 2);
        VATEntry.Amount := TaxAmount;
        VATEntry.Insert();
    end;

    local procedure UpdateTaxSetupWithNonTaxGroup(TaxGroupCode: Code[20])
    var
        TaxSetup: Record "Tax Setup";
    begin
        TaxSetup.Get();
        TaxSetup.Validate("Non-Taxable Tax Group Code", TaxGroupCode);
        TaxSetup.Modify(true);
    end;

    local procedure VerifyTaxDetail(TaxDetail: Record "Tax Detail")
    var
        TaxDetail2: Record "Tax Detail";
    begin
        TaxDetail2.SetRange("Tax Jurisdiction Code", TaxDetail."Tax Jurisdiction Code");
        TaxDetail2.SetRange("Tax Group Code", TaxDetail."Tax Group Code");
        TaxDetail2.SetRange("Tax Type", TaxDetail."Tax Type");
        TaxDetail2.SetRange("Effective Date", TaxDetail."Effective Date");
        Assert.IsTrue(TaxDetail2.FindFirst(), TaxDetailErr);
    end;

    local procedure VerifyTaxAmountsInSalesTaxesCollectedReport(TaxJurisdiction: Text; SalesTaxAmt: Decimal; TaxableAmt: Decimal; NonTaxableAmt: Decimal; ExemptAmt: Decimal; LineNo: Integer)
    var
        i: Integer;
    begin
        LibraryReportDataset.SetRange('Desc_TaxJurisdiction', TaxJurisdiction);
        for i := 1 to LineNo do
            LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesTaxAmt', SalesTaxAmt);
        LibraryReportDataset.AssertCurrentRowValueEquals('TaxableSalesAmt', TaxableAmt);
        LibraryReportDataset.AssertCurrentRowValueEquals('NonTaxableSalesAmt', NonTaxableAmt);
        LibraryReportDataset.AssertCurrentRowValueEquals('ExemptSalesAmt', ExemptAmt);
    end;

    local procedure VerifyEmptyTaxJurisdictionInSalesTaxesCollectedReport(TaxJurisdiction: Text)
    begin
        LibraryReportDataset.SetRange('Desc_TaxJurisdiction', TaxJurisdiction);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesTaxAmt', 0);
        Assert.IsFalse(LibraryReportDataset.CurrentRowHasElementTag('TaxableSalesAmt'), '');
        Assert.IsFalse(LibraryReportDataset.CurrentRowHasElementTag('NonTaxableSalesAmt'), '');
        Assert.IsFalse(LibraryReportDataset.CurrentRowHasElementTag('ExemptSalesAmt'), '');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesTaxesCollectedReqPageHandler(var SalesTaxesCollected: TestRequestPage "Sales Taxes Collected")
    begin
        SalesTaxesCollected.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

