codeunit 134290 "Non-Deductible VAT Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Non-Deductible VAT]
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryNonDeductibleVAT: Codeunit "Library - NonDeductible VAT";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit "Assert";
        isInitialized: Boolean;
        ConfirmAdjustQst: Label 'Do you want to fill the G/L Account No. field in VAT entries that are linked to G/L Entries?';

    [Test]
    [HandlerFunctions('GLVATReconciliationRequestPageHandler,ConfirmHandler')]
    procedure GLVATReconciliationWithNonDedVAT()
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        AmountType: Enum "VAT Statement Line Amount Type";
    begin
        // [SCENARIO 524882] Stan can use the "G/L - VAT Reconciliation" report to reconcile VAT entries with non-deductible VAT entries

        Initialize();
        // [GIVEN] Non-Deductible VAT Posting Setup
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] VAT Statement with the Non-Deductible VAT Posting Setup in multiple lines with different Amount Types
        // [GIVEN] Amount Type = "Non-Deductible Amount"
        // [GIVEN] Amount Type = "Non-Deductible Base"
        // [GIVEN] Amount Type = "Full Amount"
        // [GIVEN] Amount Type = "Full Base"
        CreateVATStatementTemplateAndName(VATStatementTemplate, VATStatementName);
        for AmountType := VATStatementLine."Amount Type"::"Non-Deductible Amount" to VATStatementLine."Amount Type"::"Full Base" do
            CreateVATStatementLine(
                VATStatementLine, VATStatementTemplate, VATStatementName, VATPostingSetup, AmountType);

        LibraryERM.CreateGLAccount(GLAccount);
        // [GIVEN] VAT Entry with Base = 100, Amount = 50, Non-Deductible VAT Base = 25, Non-Deductible VAT Amount = 12.5
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry.Type := VATEntry.Type::Purchase;
        VATEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATEntry."VAT Reporting Date" := WorkDate();
        VATEntry."G/L Acc. No." := GLAccount."No.";
        VATEntry.Base := LibraryRandom.RandDec(100, 2);
        VATEntry.Amount := LibraryRandom.RandDec(100, 2);
        VATEntry."Non-Deductible VAT Base" := LibraryRandom.RandDec(100, 2);
        VATEntry."Non-Deductible VAT Amount" := LibraryRandom.RandDec(100, 2);
        VATEntry.Insert();
        Commit();

        LibraryVariableStorage.Enqueue(false); // Use Additional Currency = false
        LibraryVariableStorage.Enqueue(ConfirmAdjustQst); // text for confirmation message
        LibraryVariableStorage.Enqueue(true); // confirm the message
        // [WHEN] Run "G/L - VAT Reconciliation" report
        RunGLVATReconciliation(VATStatementName, GLAccount);

        // [THEN] Report shows the correct amount
        // [THEN] Amount Type = Full Amount: Amount = 125, VAT = 62.5
        // [THEN] Amount Type = Full Base: Amount = 125, VAT = 62.5
        // [THEN] Amount Type = Non-Deductible Amount: Amount = 25, VAT = 12.5
        // [THEN] Amount Type = Non-Deductible Base: Amount = 25, VAT = 12.5
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('VAT_Statement_Line__Amount_Type_', 'Full Amount');
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', VATEntry.Base + VATEntry."Non-Deductible VAT Base");
        LibraryReportDataset.AssertElementWithValueExists('TotalVAT', VATEntry.Amount + VATEntry."Non-Deductible VAT Amount");
        LibraryReportDataset.SetRange('VAT_Statement_Line__Amount_Type_', 'Full Base');
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', VATEntry.Base + VATEntry."Non-Deductible VAT Base");
        LibraryReportDataset.AssertElementWithValueExists('TotalVAT', VATEntry.Amount + VATEntry."Non-Deductible VAT Amount");
        LibraryReportDataset.SetRange('VAT_Statement_Line__Amount_Type_', 'Non-Deductible Amount');
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', VATEntry."Non-Deductible VAT Base");
        LibraryReportDataset.AssertElementWithValueExists('TotalVAT', VATEntry."Non-Deductible VAT Amount");
        LibraryReportDataset.SetRange('VAT_Statement_Line__Amount_Type_', 'Non-Deductible Base');
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', VATEntry."Non-Deductible VAT Base");
        LibraryReportDataset.AssertElementWithValueExists('TotalVAT', VATEntry."Non-Deductible VAT Amount");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GLVATReconciliationRequestPageHandler,ConfirmHandler')]
    procedure GLVATReconciliationWithNonDedVATACY()
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        AmountType: Enum "VAT Statement Line Amount Type";
    begin
        // [SCENARIO 524882] Stan can use the "G/L - VAT Reconciliation" report to reconcile VAT entries with non-deductible VAT entries in additional currency

        Initialize();
        // [GIVEN] Additional currency is set in the General Ledger Setup
        LibraryERM.SetAddReportingCurrency(LibraryERM.CreateCurrencyWithRandomExchRates());
        // [GIVEN] Non-Deductible VAT Posting Setup
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] VAT Statement with the Non-Deductible VAT Posting Setup in multiple lines with different Amount Types
        // [GIVEN] Amount Type = "Non-Deductible Amount"
        // [GIVEN] Amount Type = "Non-Deductible Base"
        // [GIVEN] Amount Type = "Full Amount"
        // [GIVEN] Amount Type = "Full Base"
        CreateVATStatementTemplateAndName(VATStatementTemplate, VATStatementName);
        for AmountType := VATStatementLine."Amount Type"::"Non-Deductible Amount" to VATStatementLine."Amount Type"::"Full Base" do
            CreateVATStatementLine(
                VATStatementLine, VATStatementTemplate, VATStatementName, VATPostingSetup, AmountType);

        LibraryERM.CreateGLAccount(GLAccount);
        // [GIVEN] VAT Entry with "Additional-Currency Base" = 100, "Additional-Currency Amount" = 50
        // [GIVEN] Non-Deductible VAT Base ACY = 25, Non-Deductible VAT Amount ACY = 12.5
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry.Type := VATEntry.Type::Purchase;
        VATEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATEntry."VAT Reporting Date" := WorkDate();
        VATEntry."G/L Acc. No." := GLAccount."No.";
        VATEntry."Additional-Currency Base" := LibraryRandom.RandDec(100, 2);
        VATEntry."Additional-Currency Amount" := LibraryRandom.RandDec(100, 2);
        VATEntry."Non-Deductible VAT Base ACY" := LibraryRandom.RandDec(100, 2);
        VATEntry."Non-Deductible VAT Amount ACY" := LibraryRandom.RandDec(100, 2);
        VATEntry.Insert();
        Commit();

        LibraryVariableStorage.Enqueue(true); // Use Additional Currency = true
        LibraryVariableStorage.Enqueue(ConfirmAdjustQst); // text for confirmation message
        LibraryVariableStorage.Enqueue(true); // confirm the message
        // [WHEN] Run "G/L - VAT Reconciliation" report with Additional Currency
        RunGLVATReconciliation(VATStatementName, GLAccount);

        // [THEN] Report shows the correct amount
        // [THEN] Amount Type = Full Amount: Amount = 125, VAT = 62.5
        // [THEN] Amount Type = Full Base: Amount = 125, VAT = 62.5
        // [THEN] Amount Type = Non-Deductible Amount: Amount = 25, VAT = 12.5
        // [THEN] Amount Type = Non-Deductible Base: Amount = 25, VAT = 12.5
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('VAT_Statement_Line__Amount_Type_', 'Full Amount');
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', VATEntry."Additional-Currency Base" + VATEntry."Non-Deductible VAT Base ACY");
        LibraryReportDataset.AssertElementWithValueExists('TotalVAT', VATEntry."Additional-Currency Amount" + VATEntry."Non-Deductible VAT Amount ACY");
        LibraryReportDataset.SetRange('VAT_Statement_Line__Amount_Type_', 'Full Base');
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', VATEntry."Additional-Currency Base" + VATEntry."Non-Deductible VAT Base ACY");
        LibraryReportDataset.AssertElementWithValueExists('TotalVAT', VATEntry."Additional-Currency Amount" + VATEntry."Non-Deductible VAT Amount ACY");
        LibraryReportDataset.SetRange('VAT_Statement_Line__Amount_Type_', 'Non-Deductible Amount');
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', VATEntry."Non-Deductible VAT Base ACY");
        LibraryReportDataset.AssertElementWithValueExists('TotalVAT', VATEntry."Non-Deductible VAT Amount ACY");
        LibraryReportDataset.SetRange('VAT_Statement_Line__Amount_Type_', 'Non-Deductible Base');
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', VATEntry."Non-Deductible VAT Base ACY");
        LibraryReportDataset.AssertElementWithValueExists('TotalVAT', VATEntry."Non-Deductible VAT Amount ACY");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATReconciliationRequestPageHandler')]
    procedure VATReconciliationReportWithNonDedVAT()
    var
        NormalVATPostingSetup: Record "VAT Posting Setup";
        ReverseChargeVATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        VATReconciliationReport: Report "VAT Reconciliation Report";
        NormalVATDocNo: Code[20];
        ReverseChargeVATDocNo: Code[20];
        GLAccNo: Code[20];
    begin
        // [SCENARIO 524882] Stan can use the "G/L - VAT Reconciliation" report to reconcile VAT entries with non-deductible VAT entries

        Initialize();
        // [GIVEN] VAT Posting Setup with Normal Charge VAT, "VAT %" = 25 and "Non-Deductible VAT %" = 50
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(NormalVATPostingSetup);
        // [GIVEN] VAT Posting Setup with Reverse Charge VAT, "VAT %" = 25 and "Non-Deductible VAT %" = 50
        LibraryNonDeductibleVAT.CreateNonDeductibleReverseChargeVATPostingSetup(ReverseChargeVATPostingSetup);
        // [GIVEN] Purchase invoice with Normal VAT Amount = 1000, VAT Amount = 250, Non-Deductible VAT Base = 125, Non-Deductible VAT Amount = 62.5
        PostPurchDocWithVATPostingSetup(NormalVATDocNo, NormalVATPostingSetup, GLAccNo);
        // [GIVEN] Purchase invoice with Reverse Charge VAT Amount = 2000, VAT Amount = 500, Non-Deductible VAT Base = 250, Non-Deductible VAT Amount = 125
        PostPurchDocWithVATPostingSetup(ReverseChargeVATDocNo, ReverseChargeVATPostingSetup, GLAccNo);

        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetFilter("Document No.", '%1|%2', NormalVATDocNo, ReverseChargeVATDocNo);

        // [WHEN] Run "VAT Reconciliation Report"            
        VATReconciliationReport.SetTableView(GLEntry);
        VATReconciliationReport.Run();

        // [THEN] Report shows the correct totals
        // [THEN] First line: Amount = 1125, VAT - 312.5
        // [THEN] Second line: Amount = 2250, VAT - 625
        LibraryReportDataset.LoadDataSetFile();
        VATEntry.SetRange("Document No.", NormalVATDocNo);
        VATEntry.FindFirst();
        LibraryReportDataset.AssertElementWithValueExists(
            'BaseAmountPurchVAT', VATEntry.Base + VATEntry."Non-Deductible VAT Base");
        LibraryReportDataset.AssertElementWithValueExists(
            'PurchVAT', VATEntry.Amount + VATEntry."Non-Deductible VAT Amount");
        LibraryReportDataset.GetNextRow();
        VATEntry.SetRange("Document No.", ReverseChargeVATDocNo);
        VATEntry.FindFirst();
        LibraryReportDataset.AssertElementWithValueExists(
            'BaseAmountRevCharges', VATEntry.Base + VATEntry."Non-Deductible VAT Base");
        LibraryReportDataset.AssertElementWithValueExists(
            'SalesVATRevCharges', VATEntry.Amount + VATEntry."Non-Deductible VAT Amount");
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler')]
    procedure VATSettlementReverseChargeVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ExpectedSettlementAmount, ExpectedSettlementAmountACY : Decimal;
        CurrencyCode: Code[10];
        SettlementDocNo, SettlementAccNo : Code[20];
        NDVATBase, NDVATAmount, NDVATBaseACY, NDVATAmountACY : Decimal;
    begin
        // [FEATURE] [VAT Settlement]
        // [SCENARIO 507719] VAT settlement considers both deductible and non-deductible parts for reverse charge VAT

        Initialize();
        // [GIVEN] VAT Posting Setup with Reverse Charge VAT, "VAT %" = 25 and "Non-Deductible VAT %" = 50
        LibraryNonDeductibleVAT.CreateNonDeductibleReverseChargeVATPostingSetup(VATPostingSetup);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10);
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        // [GIVEN] Purchase invoice with Amount = 1000, VAT Amount = 250, Non-Deductible VAT Amount = 125
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Purchase), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        VATEntry.SetRange("Posting Date", PurchaseHeader."Posting Date");
        VATEntry.SetRange("Document No.", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        VATEntry.FindFirst();
        NDVATBase := VATEntry."Non-Deductible VAT Base";
        NDVATAmount := VATEntry."Non-Deductible VAT Amount";
        NDVATBaseACY := VATEntry."Non-Deductible VAT Base ACY";
        NDVATAmountACY := VATEntry."Non-Deductible VAT Amount ACY";
        ExpectedSettlementAmount := -Round(
            Round(PurchaseLine.Amount * VATPostingSetup."VAT %" / 100) * VATPostingSetup."Non-Deductible VAT %" / 100);
        CurrencyExchangeRate.Get(CurrencyCode, PurchaseHeader."Posting Date");
        ExpectedSettlementAmountACY :=
            -Round(
                Round(PurchaseLine.Amount * CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount") *
                (VATPostingSetup."VAT %" / 100) * VATPostingSetup."Non-Deductible VAT %" / 100);
        SettlementDocNo := LibraryUtility.GenerateGUID();
        SettlementAccNo := LibraryERM.CreateGLAccountNo();

        // [WHEN] Run "Calc. and Post VAT Settlement" report with a Post option
        RunCalcAndPostVATSettlementReport(VATPostingSetup, SettlementDocNo, SettlementAccNo, true);
        // [THEN] VAT Amount printed in the report is 125
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATAmount', ExpectedSettlementAmount);
        LibraryReportDataset.AssertElementWithValueExists('VATAmountAddCurr', ExpectedSettlementAmountACY);
        // [THEN] G/L Entry with settlement amount has value of 125
        VerifySingleGLEntryAmount(PurchaseHeader."Posting Date", SettlementAccNo, ExpectedSettlementAmount);
        // [THEN] Settlement VAT entry has negative values for the Non-Deductible VAT base and amount
        VATEntry.SetRange("Posting Date", PurchaseHeader."Posting Date");
        VATEntry.SetRange("Document No.", SettlementDocNo);
        VATEntry.SetRange(Type, VATEntry.Type::Settlement);
        Assert.RecordCount(VATEntry, 1);
        VATEntry.FindFirst();
        VATEntry.TestField("Non-Deductible VAT Base", -NDVATBase);
        VATEntry.TestField("Non-Deductible VAT Amount", -NDVATAmount);
        VATEntry.TestField("Non-Deductible VAT Base ACY", -NDVATBaseACY);
        VATEntry.TestField("Non-Deductible VAT Amount ACY", -NDVATAmountACY);
    end;

    [Test]
    [HandlerFunctions('VATReconciliationDeductibleOnlyRequestPageHandler')]
    procedure VATReconciliationPurchInv100PctNonDedDeductibleOnly()
    var
        VATEntry: Record "VAT Entry";
        GLAccNo: Code[20];
        DocNo: Code[20];
    begin
        // [SCENARIO 637506] Purchase invoice with 100% Non-Deductible VAT reports 0 deductible base and VAT with "Deductible VAT Only"
        Initialize();

        // [GIVEN] Purchase invoice posted with VAT 25% and Non-Deductible VAT 100%
        PostPurchInvWithNonDedDetail(25, 100, GLAccNo, DocNo, VATEntry);

        // [WHEN] Run "VAT Reconciliation Report" with "VAT Amount Type" = "Deductible VAT Only"
        RunVATReconciliationReportForDoc(DocNo);

        // [THEN] Base Amount Purchase VAT = 0 and Purchase VAT = 0 (fully non-deductible)
        VerifyReportRow(GLAccNo, 'BaseAmountPurchVAT', 0, 'PurchVAT', 0);
    end;

    [Test]
    [HandlerFunctions('VATReconciliationDeductibleOnlyRequestPageHandler')]
    procedure VATReconciliationPurchInv75PctNonDedDeductibleOnly()
    var
        VATEntry: Record "VAT Entry";
        GLAccNo: Code[20];
        DocNo: Code[20];
    begin
        // [SCENARIO 637506] Purchase invoice with 75% Non-Deductible VAT reports only the deductible base and VAT with "Deductible VAT Only"
        Initialize();

        // [GIVEN] Purchase invoice posted with VAT 25% and Non-Deductible VAT 75%
        PostPurchInvWithNonDedDetail(25, 75, GLAccNo, DocNo, VATEntry);

        // [WHEN] Run "VAT Reconciliation Report" with "Deductible VAT Only"
        RunVATReconciliationReportForDoc(DocNo);

        // [THEN] Base Amount Purchase VAT and Purchase VAT equal the deductible portion of the VAT entry
        VerifyReportRow(GLAccNo, 'BaseAmountPurchVAT', VATEntry.Base, 'PurchVAT', VATEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('VATReconciliationDeductibleOnlyRequestPageHandler')]
    procedure VATReconciliationGenJnl100PctNonDedDeductibleOnly()
    var
        VATEntry: Record "VAT Entry";
        GLAccNo: Code[20];
        DocNo: Code[20];
    begin
        // [SCENARIO 637506] General journal with 100% Non-Deductible VAT reports 0 deductible base and VAT with "Deductible VAT Only"
        Initialize();

        // [GIVEN] General journal line posted with VAT 25% and Non-Deductible VAT 100%
        PostGenJnlWithNonDedDetail(25, 100, GLAccNo, DocNo, VATEntry);

        // [WHEN] Run "VAT Reconciliation Report" with "Deductible VAT Only"
        RunVATReconciliationReportForDoc(DocNo);

        // [THEN] Base Amount Purchase VAT = 0 and Purchase VAT = 0
        VerifyReportRow(GLAccNo, 'BaseAmountPurchVAT', 0, 'PurchVAT', 0);
    end;

    [Test]
    [HandlerFunctions('VATReconciliationDeductibleOnlyRequestPageHandler')]
    procedure VATReconciliationGenJnl75PctNonDedDeductibleOnly()
    var
        VATEntry: Record "VAT Entry";
        GLAccNo: Code[20];
        DocNo: Code[20];
    begin
        // [SCENARIO 637506] General journal with 75% Non-Deductible VAT reports only the deductible base and VAT with "Deductible VAT Only"
        Initialize();

        // [GIVEN] General journal line posted with VAT 25% and Non-Deductible VAT 75%
        PostGenJnlWithNonDedDetail(25, 75, GLAccNo, DocNo, VATEntry);

        // [WHEN] Run "VAT Reconciliation Report" with "Deductible VAT Only"
        RunVATReconciliationReportForDoc(DocNo);

        // [THEN] Base Amount Purchase VAT and Purchase VAT equal the deductible portion of the VAT entry
        VerifyReportRow(GLAccNo, 'BaseAmountPurchVAT', VATEntry.Base, 'PurchVAT', VATEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('VATReconciliationDeductibleOnlyRequestPageHandler')]
    procedure VATReconciliationInvoiceVsJournalParityDeductibleOnly()
    var
        InvVATEntry: Record "VAT Entry";
        JnlVATEntry: Record "VAT Entry";
        InvGLAccNo: Code[20];
        JnlGLAccNo: Code[20];
        InvDocNo: Code[20];
        JnlDocNo: Code[20];
    begin
        // [SCENARIO 637506] Purchase invoice and general journal with the same Non-Deductible VAT setup report the deductible portion consistently
        Initialize();

        // [GIVEN] A purchase invoice and a general journal, both with VAT 25% and Non-Deductible VAT 75%
        PostPurchInvWithNonDedDetail(25, 75, InvGLAccNo, InvDocNo, InvVATEntry);
        PostGenJnlWithNonDedDetail(25, 75, JnlGLAccNo, JnlDocNo, JnlVATEntry);

        // [WHEN] Run "VAT Reconciliation Report" with "Deductible VAT Only" for each document
        // [THEN] Both report only the deductible base and VAT of their VAT entries
        RunVATReconciliationReportForDoc(InvDocNo);
        VerifyReportRow(InvGLAccNo, 'BaseAmountPurchVAT', InvVATEntry.Base, 'PurchVAT', InvVATEntry.Amount);
        RunVATReconciliationReportForDoc(JnlDocNo);
        VerifyReportRow(JnlGLAccNo, 'BaseAmountPurchVAT', JnlVATEntry.Base, 'PurchVAT', JnlVATEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('VATReconciliationDeductibleOnlyRequestPageHandler')]
    procedure VATReconciliationFullyDeductiblePurchVATDeductibleOnly()
    var
        VATEntry: Record "VAT Entry";
        GLAccNo: Code[20];
        DocNo: Code[20];
    begin
        // [SCENARIO 637506] A purchase invoice without Non-Deductible VAT is unaffected by the "Deductible VAT Only" option
        Initialize();

        // [GIVEN] Purchase invoice posted with VAT 25% and Non-Deductible VAT 0%
        PostPurchInvWithNonDedDetail(25, 0, GLAccNo, DocNo, VATEntry);

        // [WHEN] Run "VAT Reconciliation Report" with "Deductible VAT Only"
        RunVATReconciliationReportForDoc(DocNo);

        // [THEN] The full base and VAT are reported because nothing is non-deductible
        VerifyReportRow(GLAccNo, 'BaseAmountPurchVAT', VATEntry.Base, 'PurchVAT', VATEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('VATReconciliationDeductibleOnlyRequestPageHandler')]
    procedure VATReconciliationSalesVATUnaffectedByDeductibleOnly()
    var
        VATEntry: Record "VAT Entry";
        GLAccNo: Code[20];
        DocNo: Code[20];
    begin
        // [SCENARIO 637506] The "Deductible VAT Only" option does not change the Sales VAT columns
        Initialize();

        // [GIVEN] A posted sales invoice with Normal VAT
        PostSalesInvoiceNormalVAT(GLAccNo, DocNo, VATEntry);

        // [WHEN] Run "VAT Reconciliation Report" with "Deductible VAT Only"
        RunVATReconciliationReportForDoc(DocNo);

        // [THEN] Base Amount Sales VAT and Sales VAT are reported as the negated VAT entry values, unchanged
        VerifyReportRow(GLAccNo, 'BaseAmountSalesVAT', -VATEntry.Base, 'SalesVAT', -VATEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('VATReconciliationDeductibleOnlyRequestPageHandler')]
    procedure VATReconciliationReverseChargeNonDedDeductibleOnly()
    var
        VATEntry: Record "VAT Entry";
        GLAccNo: Code[20];
        DocNo: Code[20];
    begin
        // [SCENARIO 637506] Reverse Charge VAT with Non-Deductible VAT reports only the deductible portion with "Deductible VAT Only"
        Initialize();

        // [GIVEN] Purchase invoice with Reverse Charge VAT 25% and Non-Deductible VAT 75%
        PostPurchInvReverseChargeNonDed(25, 75, GLAccNo, DocNo, VATEntry);

        // [WHEN] Run "VAT Reconciliation Report" with "Deductible VAT Only"
        RunVATReconciliationReportForDoc(DocNo);

        // [THEN] Base Amount Reverse Charges and Sales VAT Reverse Charges equal the deductible portion
        VerifyReportRow(GLAccNo, 'BaseAmountRevCharges', VATEntry.Base, 'SalesVATRevCharges', VATEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('VATReconciliationDeductibleOnlyRequestPageHandler')]
    procedure VATReconciliationZeroLineDoesNotContaminateNonDed()
    var
        NonDedVATEntry: Record "VAT Entry";
        NonDedGLAccNo: Code[20];
        ZeroGLAccNo: Code[20];
        DocNo: Code[20];
    begin
        // [SCENARIO 637506] A zero-VAT line sharing the transaction does not contaminate the 100% Non-Deductible line totals
        Initialize();

        // [GIVEN] Purchase invoice with a 100% Non-Deductible line and a 0% VAT line under the same transaction
        PostPurchInvNonDedPlusZeroLine(NonDedGLAccNo, ZeroGLAccNo, DocNo, NonDedVATEntry);

        // [WHEN] Run "VAT Reconciliation Report" with "Deductible VAT Only"
        RunVATReconciliationReportForDoc(DocNo);

        // [THEN] The 100% Non-Deductible account still reports 0 base and 0 VAT (no rounding/zero-line leakage)
        VerifyReportRow(NonDedGLAccNo, 'BaseAmountPurchVAT', 0, 'PurchVAT', 0);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Non-Deductible VAT Reports");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Non-Deductible VAT Reports");
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryNonDeductibleVAT.EnableNonDeductibleVAT();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySetupStorage.Save(Database::"VAT Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Non-Deductible VAT Reports");
    end;

    local procedure PostPurchDocWithVATPostingSetup(var DocNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; var GLAccNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        GLAccNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Purchase);
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccNo, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostPurchInvWithNonDedDetail(VATPct: Decimal; NonDedPct: Decimal; var GLAccNo: Code[20]; var DocNo: Code[20]; var VATEntry: Record "VAT Entry")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryNonDeductibleVAT.CreateVATPostingSetupWithNonDeductibleDetail(VATPostingSetup, VATPct, NonDedPct);
        PostPurchDocWithVATPostingSetup(DocNo, VATPostingSetup, GLAccNo);
        FindPurchaseVATEntry(VATEntry, DocNo);
    end;

    local procedure PostPurchInvReverseChargeNonDed(VATPct: Decimal; NonDedPct: Decimal; var GLAccNo: Code[20]; var DocNo: Code[20]; var VATEntry: Record "VAT Entry")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryNonDeductibleVAT.CreateNonDeductibleReverseChargeVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Validate("Non-Ded. Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Non-Deductible VAT %", NonDedPct);
        VATPostingSetup.Modify(true);
        PostPurchDocWithVATPostingSetup(DocNo, VATPostingSetup, GLAccNo);
        FindPurchaseVATEntry(VATEntry, DocNo);
    end;

    local procedure PostGenJnlWithNonDedDetail(VATPct: Decimal; NonDedPct: Decimal; var GLAccNo: Code[20]; var DocNo: Code[20]; var VATEntry: Record "VAT Entry")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryNonDeductibleVAT.CreateVATPostingSetupWithNonDeductibleDetail(VATPostingSetup, VATPct, NonDedPct);
        GLAccNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Purchase);
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccNo,
            LibraryRandom.RandDecInRange(100, 1000, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
        DocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FindPurchaseVATEntry(VATEntry, DocNo);
    end;

    local procedure PostSalesInvoiceNormalVAT(var GLAccNo: Code[20]; var DocNo: Code[20]; var VATEntry: Record "VAT Entry")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.SetInvoiceRounding(false);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 25));
        GLAccNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Sale);
        LibrarySales.CreateSalesHeader(
            SalesHeader, SalesHeader."Document Type"::Invoice,
            LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccNo, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 1000, 2));
        SalesLine.Modify(true);
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.FindFirst();
    end;

    local procedure PostPurchInvNonDedPlusZeroLine(var NonDedGLAccNo: Code[20]; var ZeroGLAccNo: Code[20]; var DocNo: Code[20]; var NonDedVATEntry: Record "VAT Entry")
    var
        NonDedVATPostingSetup: Record "VAT Posting Setup";
        ZeroVATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryNonDeductibleVAT.CreateVATPostingSetupWithNonDeductibleDetail(NonDedVATPostingSetup, 25, 100);
        NonDedGLAccNo := LibraryERM.CreateGLAccountWithVATPostingSetup(NonDedVATPostingSetup, "General Posting Type"::Purchase);
        CreateZeroVATSetupSameBusGroup(NonDedVATPostingSetup."VAT Bus. Posting Group", ZeroVATPostingSetup);
        ZeroGLAccNo := LibraryERM.CreateGLAccountWithVATPostingSetup(ZeroVATPostingSetup, "General Posting Type"::Purchase);
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(NonDedVATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", NonDedGLAccNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 1000, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", ZeroGLAccNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 1000, 2));
        PurchaseLine.Modify(true);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        NonDedVATEntry.SetRange("Document No.", DocNo);
        NonDedVATEntry.SetRange("VAT Prod. Posting Group", NonDedVATPostingSetup."VAT Prod. Posting Group");
        NonDedVATEntry.FindFirst();
    end;

    local procedure FindPurchaseVATEntry(var VATEntry: Record "VAT Entry"; DocNo: Code[20])
    begin
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.FindFirst();
    end;

    local procedure CreateVATStatementTemplateAndName(var VATStatementTemplate: Record "VAT Statement Template"; var VATStatementName: Record "VAT Statement Name")
    begin
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        VATStatementTemplate.Validate("VAT Statement Report ID", REPORT::"VAT Statement");
        VATStatementTemplate.Modify(true);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
    end;

    local procedure CreateVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; VATStatementTemplate: Record "VAT Statement Template"; VATStatementName: Record "VAT Statement Name"; VATPostingSetup: Record "VAT Posting Setup"; VATStatementLineAmountType: Enum "VAT Statement Line Amount Type")
    begin
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementTemplate.Name, VATStatementName.Name);
        VATStatementLine.Validate("Row No.", Format(LibraryRandom.RandInt(100)));
        VATStatementLine.Validate(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.Validate("Gen. Posting Type", VATStatementLine."Gen. Posting Type"::Purchase);
        VATStatementLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATStatementLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATStatementLine.Validate("Amount Type", VATStatementLineAmountType);
        VATStatementLine.Modify(true);
    end;

    local procedure CreateZeroVATSetupSameBusGroup(VATBusPostingGroupCode: Code[20]; var ZeroVATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(ZeroVATPostingSetup, VATBusPostingGroupCode, VATProductPostingGroup.Code);
        ZeroVATPostingSetup.Validate("VAT Calculation Type", ZeroVATPostingSetup."VAT Calculation Type"::"Normal VAT");
        ZeroVATPostingSetup.Validate("VAT %", 0);
        ZeroVATPostingSetup.Validate("VAT Identifier", VATProductPostingGroup.Code);
        ZeroVATPostingSetup.Modify(true);
    end;

    local procedure RunCalcAndPostVATSettlementReport(VATPostingSetup: Record "VAT Posting Setup"; DocumentNo: Code[20]; SettlementAccNo: Code[20]; Post: Boolean)
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
    begin
        VATPostingSetup.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        CalcAndPostVATSettlement.SetTableView(VATPostingSetup);
        CalcAndPostVATSettlement.InitializeRequest(WorkDate(), WorkDate(), WorkDate(), DocumentNo, SettlementAccNo, false, Post);
        Commit();
        CalcAndPostVATSettlement.Run();
    end;

    local procedure RunGLVATReconciliation(VATStatementName: Record "VAT Statement Name"; GLAccount: Record "G/L Account")
    var
        GLVATReconciliation: Report "G/L - VAT Reconciliation";
    begin
        VATStatementName.SetRecFilter();
        GLAccount.SetRecFilter();
        GLVATReconciliation.SetTableView(VATStatementName);
        GLVATReconciliation.SetTableView(GLAccount);
        GLVATReconciliation.Run();
    end;

    local procedure RunVATReconciliationReportForDoc(DocNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        VATReconciliationReport: Report "VAT Reconciliation Report";
    begin
        GLEntry.SetRange("Document No.", DocNo);
        Commit();
        VATReconciliationReport.SetTableView(GLEntry);
        VATReconciliationReport.Run();
    end;

    local procedure VerifySingleGLEntryAmount(PostingDate: Date; GLAccNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        Assert.RecordCount(GLEntry, 1);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyReportRow(GLAccNo: Code[20]; BaseElementName: Text; ExpectedBase: Decimal; VATElementName: Text; ExpectedVAT: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('GLAccountNo_GLEntry', GLAccNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(BaseElementName, ExpectedBase);
        LibraryReportDataset.AssertCurrentRowValueEquals(VATElementName, ExpectedVAT);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATReconciliationDeductibleOnlyRequestPageHandler(var VATReconciliationReport: TestRequestPage "VAT Reconciliation Report")
    begin
        VATReconciliationReport.VATReconciliationAmountType.SetValue(Enum::"VAT Reconciliation Amount Type"::"Deductible VAT Only");
        VATReconciliationReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementRequestPageHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    begin
        if CalcAndPostVATSettlement.Editable then;
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLVATReconciliationRequestPageHandler(var GLVATReconciliation: TestRequestPage "G/L - VAT Reconciliation")
    begin
        GLVATReconciliation.UseAmtsInAddCurr.SetValue(LibraryVariableStorage.DequeueBoolean());
        GLVATReconciliation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATReconciliationRequestPageHandler(var VATReconciliationReport: TestRequestPage "VAT Reconciliation Report")
    begin
        VATReconciliationReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}