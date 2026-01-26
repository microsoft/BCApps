codeunit 144050 "ERM Finance Reports"
{
    //  1. Verify error for blank Posting Date on VAT-Vies Declaration Tax - DE Report.
    //  2. Verify Vendor Detailed Aging Report without any Vendor No. filter.
    //  3. Verify Vendor Detailed Aging Report with one Vendor No. as filter.
    //  4. Verify Vendor Detailed Aging Report with Vendor No. range as filter.
    //  5. Verify error for blank Date Filter on  G/L Total Balance Report.
    //  6. Verify G/L Total Balance Report.
    //  7. Verify error for blank Date Filter on Customer Total Balance Report.
    //  8. Verify Customer Total Balance Report.
    //  9. Verify error for blank Date Filter on Vendor Total Balance Report.
    // 10. Verify Vendor Total Balance Report.
    // 11. Verify G/L - VAT Reconciliation Report with Unrealized VAT TRUE when only one payment discount is posted to the account.
    // 12. Verify G/L - VAT Reconciliation Report with Unrealized VAT FALSE when only one payment discount is posted to the account.
    // 13. Verify G/L - VAT Reconciliation Report with Unrealized VAT TRUE when multiple payment discount is posted to the account.
    // 14. Verify G/L - VAT Reconciliation Report with Unrealized VAT FALSE when multilple payment discount is posted to the account.
    // 
    //  TFS_TS_ID = 326560
    //  Covers Test cases :
    //  ----------------------------------------------------------------
    //  Test Function Name                                       TFS ID
    //  ----------------------------------------------------------------
    //  VATViesDeclarationTaxReportPostDateError                 151263
    // 
    //  Covers Test cases: for WI - 326561
    //  ---------------------------------------------------------------------------------------------------------
    //  Test Function Name                                                                                TFS ID
    //  ---------------------------------------------------------------------------------------------------------
    //  VendDtldAgingReportWithoutVendorFilter, VendDtldAgingReportWithVendorNoFilter,
    //  VendDtldAgingReportWithVendorNoRangeFilter,
    //  GLTotalBalanceReportDateFilterError, GLTotalBalanceReport,
    //  CustomerTotalBalanceReportDateFilterError, CustomerTotalBalanceReport,
    //  VendorTotalBalanceReportDateFilterError, VendorTotalBalanceReport                                 151818
    // 
    //  Covers Test cases: for WI - 326536
    //  ---------------------------------------------------------------------------------------------------------
    //  Test Function Name                                                                                TFS ID
    //  ---------------------------------------------------------------------------------------------------------
    // GLVATReconciliationWithUnrealizedVATTrueAndPmtDisc                                             157359
    // GLVATReconciliationWithUnrealizedVATFalseAndPmtDisc                                            157318
    // GLVATReconciliationWithUnrealizedVATTrueMultipleDisc                                           157361
    // GLVATReconciliationWithUnrealizedVATFalseMultipleDisc                                          157319

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        FilterValue: Label 'No.: %1';
        PostingDateError: Label 'Specify a filter for the %1 field in the %2 table.';
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        RangeFilter: Label '%1|%2';
        RemainingAmountCaption: Label 'CurrTotalBuffer2TotAmt';
        VendFilterCaption: Label 'VendFilter';
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        GLAccountNoCaption: Label 'GLAccountNo';
        PeriodDebitAmountCaption: Label 'PeriodDebitAmount';
        VendorNoCaption: Label 'Vendor_Vendor__No__';
        CustomerNoCaption: Label 'No_Cust';

    [Test]
    [HandlerFunctions('VATViesDeclarationTaxHandler')]
    [Scope('OnPrem')]
    procedure VATViesDeclarationTaxReportPostDateError()
    var
        VATEntry: Record "VAT Entry";
    begin
        // Verify error for blank VAT Reporting Date on VAT-Vies Declaration Tax - DE Report.

        // Setup.
        Initialize();
        Commit();

        // Exercise.
        asserterror REPORT.Run(REPORT::"VAT-Vies Declaration Tax - DE");

        // Verify: Verify error for blank VAT Reporting Date.
        Assert.ExpectedError(StrSubstNo(PostingDateError, VATEntry.FieldCaption("VAT Reporting Date"), VATEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('VendorDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendDtldAgingReportWithoutVendorFilter()
    begin
        // Verify Vendor Detailed Aging Report without any Vendor No. filter.

        // Setup.
        Initialize();
        Commit();

        // Exercise and Verify.
        RunVendorDetailedAgingReportAndVerify(WorkDate(), '', '');  // Blank values for Vendor No.
    end;

    [Test]
    [HandlerFunctions('VendorDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendDtldAgingReportWithVendorNoFilter()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Vendor Detailed Aging Report with one Vendor No. as filter.

        // Setup: Create and post Purchase Invoice.
        Initialize();
        CreateAndPostPurchaseInvoice(PurchaseHeader);

        // Exercise and Verify.
        RunVendorDetailedAgingReportAndVerify(
          PurchaseHeader."Due Date", PurchaseHeader."Buy-from Vendor No.", StrSubstNo(FilterValue, PurchaseHeader."Buy-from Vendor No."));
    end;

    [Test]
    [HandlerFunctions('VendorDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendDtldAgingReportWithVendorNoRangeFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
    begin
        // Verify Vendor Detailed Aging Report with Vendor No. range as filter.

        // Setup: Create and post Purchase Invoice for different Vendors.
        Initialize();
        CreateAndPostPurchaseInvoice(PurchaseHeader);
        CreateAndPostPurchaseInvoice(PurchaseHeader2);

        // Exercise and Verify.
        RunVendorDetailedAgingReportAndVerify(
          PurchaseHeader."Due Date", StrSubstNo(RangeFilter, PurchaseHeader."Buy-from Vendor No.", PurchaseHeader2."Buy-from Vendor No."),
          StrSubstNo(FilterValue, StrSubstNo(RangeFilter, PurchaseHeader."Buy-from Vendor No.", PurchaseHeader2."Buy-from Vendor No.")));
    end;

    [Test]
    [HandlerFunctions('GLTotalBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLTotalBalanceReportDateFilterError()
    var
        GLAccount: Record "G/L Account";
    begin
        // Verify error for blank Date Filter on  G/L Total Balance Report.

        // Setup: Enqueue values for GLTotalBalanceRequestPageHandler.
        Initialize();
        LibraryVariableStorage.Enqueue(0D);
        LibraryVariableStorage.Enqueue('');
        Commit();

        // Exercise.
        asserterror REPORT.Run(REPORT::"G/L Total-Balance");

        // Verify: Verify error for blank Posting Date.
        Assert.ExpectedError(StrSubstNo(PostingDateError, GLAccount.FieldCaption("Date Filter"), GLAccount.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('GLTotalBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLTotalBalanceReport()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify G/L Total Balance Report.

        // Setup: Create and post Gen.Journal Line for G/L Account.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        CreateAndPostGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");

        // Exercise.
        REPORT.Run(REPORT::"G/L Total-Balance");

        // Verify: Verify Amount on G/L Total-Balance Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyAmountOnReport(GenJournalLine."Account No.", GLAccountNoCaption, PeriodDebitAmountCaption, GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerTotalBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerTotalBalanceReportDateFilterError()
    var
        Customer: Record Customer;
    begin
        // Verify error for blank Date Filter on Customer Total Balance Report.

        // Setup: Enqueue values for CustomerTotalBalanceRequestPageHandler.
        Initialize();
        LibraryVariableStorage.Enqueue(0D);
        LibraryVariableStorage.Enqueue('');
        Commit();

        // Exercise.
        asserterror REPORT.Run(REPORT::"Customer Total-Balance");

        // Verify: Verify error for blank Posting Date.
        Assert.ExpectedError(StrSubstNo(PostingDateError, Customer.FieldCaption("Date Filter"), Customer.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('CustomerTotalBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerTotalBalanceReport()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Customer Total Balance Report.

        // Setup: Create and post Gen.Journal Line for Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.");

        // Exercise.
        REPORT.Run(REPORT::"Customer Total-Balance");

        // Verify: Verify Amount on Customer Total-Balance Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyAmountOnReport(GenJournalLine."Account No.", CustomerNoCaption, PeriodDebitAmountCaption, GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('VendorTotalBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorTotalBalanceReportDateFilterError()
    var
        Vendor: Record Vendor;
    begin
        // Verify error for blank Date Filter on Vendor Total Balance Report.

        // Setup: Enqueue values for VendorTotalBalanceRequestPageHandler.
        Initialize();
        LibraryVariableStorage.Enqueue(0D);
        LibraryVariableStorage.Enqueue('');
        Commit();

        // Exercise.
        asserterror REPORT.Run(REPORT::"Vendor Total-Balance");

        // Verify: Verify error for blank Posting Date.
        Assert.ExpectedError(StrSubstNo(PostingDateError, Vendor.FieldCaption("Date Filter"), Vendor.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('VendorTotalBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorTotalBalanceReport()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Vendor Total Balance Report.

        // Setup: Create and post Gen.Journal Line for Vendor.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.");

        // Exercise.
        REPORT.Run(REPORT::"Vendor Total-Balance");

        // Verify: Verify Amount on Vendor Total-Balance Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyAmountOnReport(GenJournalLine."Account No.", VendorNoCaption, PeriodDebitAmountCaption, GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,VATAdvNotAccProofReqPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure GLVATReconciliationWithUnrealizedVATTrueAndPmtDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify G/L - VAT Reconciliation Report with Unrealized VAT TRUE when only one payment discount is posted to the account.
        GLVATReconciliationWithPaymentDiscount(true, VATPostingSetup."Unrealized VAT Type"::Percentage);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,VATAdvNotAccProofReqPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure GLVATReconciliationWithUnrealizedVATFalseAndPmtDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify G/L - VAT Reconciliation Report with Unrealized VAT FALSE when only one payment discount is posted to the account.
        GLVATReconciliationWithPaymentDiscount(false, VATPostingSetup."Unrealized VAT Type"::" ");
    end;

    local procedure GLVATReconciliationWithPaymentDiscount(UnrealizedVAT: Boolean; UnrealizedVATType: Option)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create and post Sales Invoice, Apply the Payment over Invoice.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateAndUpdateReportSelection();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        SetupForGLVATReconciliation(SalesLine, VATPostingSetup, UnrealizedVAT, UnrealizedVATType);

        // Exercise and Verification:
        RunAndVerifyGLVATReconciliation(SalesLine);

        // Tear Down:
        RollbackGLAndVATSetup(GeneralLedgerSetup."Unrealized VAT", VATPostingSetup);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,VATAdvNotAccProofReqPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure GLVATReconciliationWithUnrealizedVATTrueMultipleDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify G/L - VAT Reconciliation Report with Unrealized VAT TRUE when multiple payment discount is posted to the account.
        GLVATReconciliationWithMultiplePmtDisc(true, VATPostingSetup."Unrealized VAT Type"::Percentage);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,VATAdvNotAccProofReqPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure GLVATReconciliationWithUnrealizedVATFalseMultipleDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify G/L - VAT Reconciliation Report with Unrealized VAT FALSE when multilple payment discount is posted to the account.
        GLVATReconciliationWithMultiplePmtDisc(false, VATPostingSetup."Unrealized VAT Type"::" ");
    end;

    local procedure GLVATReconciliationWithMultiplePmtDisc(UnrealizedVAT: Boolean; UnrealizedVATType: Option)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create and post Sales Invoice with multiple lines, Apply the Payment over Invoice.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateAndUpdateReportSelection();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        SetupForGLVATReconciliation(SalesLine, VATPostingSetup, UnrealizedVAT, UnrealizedVATType);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLine(SalesLine, SalesHeader, CreateGLAccountWithVAT(VATPostingSetup));

        // Exercise and Verification:
        RunAndVerifyGLVATReconciliation(SalesLine);

        // Tear Down:
        RollbackGLAndVATSetup(GeneralLedgerSetup."Unrealized VAT", VATPostingSetup);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Finance Reports");
        LibraryVariableStorage.Clear();
        Clear(LibraryReportDataset);
        LibraryERMCountryData.UpdateGeneralPostingSetup();
    end;

    local procedure CalculateAmount(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20])
    begin
        GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Posting Date", WorkDate());
        GLEntry.CalcSums(Amount, "VAT Amount");
    end;

    local procedure CalculateRemAmountAsOfDueDate(DueDate: Date; VendorNoFilter: Text) RemAmount: Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetFilter("Vendor No.", VendorNoFilter);
        VendorLedgerEntry.SetFilter("Due Date", '%1..%2', 0D, DueDate);
        VendorLedgerEntry.SetRange("Currency Code", '');
        if VendorLedgerEntry.FindSet() then
            repeat
                VendorLedgerEntry.CalcFields("Remaining Amount");
                RemAmount += VendorLedgerEntry."Remaining Amount";
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure CreateAndUpdateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateAndUpdateReportSelection()
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"Sales VAT Acc. Proof");
        if not ReportSelections.FindFirst() then begin
            ReportSelections.Init();
            ReportSelections.Validate(Usage, ReportSelections.Usage::"Sales VAT Acc. Proof");
            ReportSelections.Validate(Sequence, Format(LibraryRandom.RandInt(10)));
            ReportSelections.Insert(true);
            ReportSelections.Validate("Report ID", REPORT::"G/L - VAT Reconciliation");
            ReportSelections.Modify(true);
        end;
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    begin
        CreateGenJournalLine(
          GenJournalLine, AccountType, GenJournalLine."Document Type"::" ", AccountNo, LibraryRandom.RandDec(100, 2));  // Use Random Amount.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Enqueue values for various RequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Posting Date");
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");
    end;

    local procedure CreateAndPostGenGeneralLineAndApplyEntries(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournal: TestPage "General Journal";
    begin
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Payment, AccountNo, 0);  // Taken 0 for Amount as this is not important.
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        Commit();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."Apply Entries".Invoke();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(100, 2));  // Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Random value for Direct Unit Cost.
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);  // Use Random Amount.
    end;

    local procedure CreateGLAccountWithVAT(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; No: Code[20])
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", No,
          LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));  // Using Random value for Unit Price.
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateAndUpdateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        CreateSalesLine(SalesLine, SalesHeader, CreateGLAccountWithVAT(VATPostingSetup));
    end;

    local procedure RollbackGLAndVATSetup(UnrealizedVAT: Boolean; VATPostingSetup: Record "VAT Posting Setup")
    begin
        UpdateUnrealizedVATSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type", VATPostingSetup."Sales VAT Unreal. Account");
        UpdateGeneralLedgerSetup(UnrealizedVAT);
    end;

    local procedure RunVendorDetailedAgingReportAndVerify(EndingDate: Date; VendorNo: Text[50]; VendorFilterValue: Text[50])
    var
        RemAmount: Decimal;
    begin
        // Calculate Remaining Amount till Due Date.
        RemAmount := CalculateRemAmountAsOfDueDate(EndingDate, VendorNo);

        // Enqueue for VendorDetailedAgingRequestPageHandler.
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(VendorNo);

        // Exercise: Run Vendor Detailed Aging Report.
        REPORT.Run(REPORT::"Vendor Detailed Aging");

        // Verify: Verify Vendor filter and Remaining Amount on the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VendFilterCaption, VendorFilterValue);
        LibraryReportDataset.AssertElementWithValueExists(RemainingAmountCaption, RemAmount);
    end;

    local procedure RunAndVerifyGLVATReconciliation(SalesLine: Record "Sales Line")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        VATStatement: TestPage "VAT Statement";
    begin
        // Post Sales Invoice.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Make Payment against Invoice and Apply the Payment over Invoice.
        CreateAndPostGenGeneralLineAndApplyEntries(GenJournalLine, SalesHeader."Sell-to Customer No.");
        CalculateAmount(GLEntry, GeneralPostingSetup."Sales Pmt. Disc. Debit Acc.");
        Commit();  // Commit required to run the report.
        VATStatement.OpenView();

        // Exercise: Run G/L - VAT Reconciliation report.
        VATStatement.GLVATReconciliation.Invoke();  // VAT Adv. Not. Acc. Proof.

        // Verify: Verify Payment Discount amount and VAT amount on G/L - VAT Reconciliation report.
        LibraryReportDataset.LoadDataSetFile();
        // VerifyAmountOnReport(GeneralPostingSetup."Sales Pmt. Disc. Debit Acc.",GLAccountNo,AmountCaption,ROUND(GLEntry.Amount));
        // VerifyAmountOnReport(GeneralPostingSetup."Sales Pmt. Disc. Debit Acc.",GLAccountNo,VATControlCaption,ROUND(GLEntry."VAT Amount"));
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure SetupForGLVATReconciliation(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVAT: Boolean; UnrealizedVATType: Option)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.SetUnrealizedVAT(UnrealizedVAT);
        LibraryERM.FindGLAccount(GLAccount);
        UpdateUnrealizedVATSetup(VATPostingSetup, UnrealizedVATType, GLAccount."No.");
        CreateSalesInvoice(SalesLine, VATPostingSetup);
    end;

    local procedure UpdateGeneralLedgerSetup(UnrealizedVAT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateUnrealizedVATSetup(VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVATType: Option; SalesVATUnrealAccount: Code[20])
    begin
        VATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedVATType);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", SalesVATUnrealAccount);
        VATPostingSetup.Modify(true);
    end;

    local procedure VerifyAmountOnReport(AccountNo: Code[20]; AccountNoCaption: Text[50]; AmountCaption: Text[50]; Amount: Decimal)
    begin
        LibraryReportDataset.SetRange(AccountNoCaption, AccountNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(AmountCaption, Amount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();  // Set Applies To ID.
        ApplyCustomerEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATViesDeclarationTaxHandler(var VATViesDeclarationTaxDE: TestRequestPage "VAT-Vies Declaration Tax - DE")
    var
        RepPeriod: Option January,February,March,April,May,June,July,August,September,October,November,December,"1. Quarter","2. Quarter","3. Quarter","4. Quarter","Jan/Feb","April/May","July/Aug","Oct/Nov","Calendar Year";
    begin
        VATViesDeclarationTaxDE.RepPeriod.SetValue(RepPeriod::January);  // Setting value for control 'Reporting Period'.
        VATViesDeclarationTaxDE.DateSignature.SetValue(WorkDate());  // Setting value for control 'Date of Signature'.
        VATViesDeclarationTaxDE."VAT Entry".SetFilter("VAT Reporting Date", Format(0D));
        VATViesDeclarationTaxDE.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorDetailedAgingRequestPageHandler(var VendorDetailedAging: TestRequestPage "Vendor Detailed Aging")
    var
        EndingDate: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(EndingDate);  // Dequeue variable.
        LibraryVariableStorage.Dequeue(No);  // Dequeue variable.
        VendorDetailedAging.EndingDate.SetValue(EndingDate);  // Control use for Ending Date.
        VendorDetailedAging.Vendor.SetFilter("No.", No);
        VendorDetailedAging.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLTotalBalanceRequestPageHandler(var GLTotalBalance: TestRequestPage "G/L Total-Balance")
    var
        DateFilter: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(DateFilter);  // Dequeue variable.
        LibraryVariableStorage.Dequeue(No);  // Dequeue variable.
        GLTotalBalance."G/L Account".SetFilter("No.", No);
        GLTotalBalance."G/L Account".SetFilter("Date Filter", Format(DateFilter));
        GLTotalBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTotalBalanceRequestPageHandler(var CustomerTotalBalance: TestRequestPage "Customer Total-Balance")
    var
        DateFilter: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(DateFilter);  // Dequeue variable.
        LibraryVariableStorage.Dequeue(No);  // Dequeue variable.
        CustomerTotalBalance.Customer.SetFilter("No.", No);
        CustomerTotalBalance.Customer.SetFilter("Date Filter", Format(DateFilter));
        CustomerTotalBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorTotalBalanceRequestPageHandler(var VendorTotalBalance: TestRequestPage "Vendor Total-Balance")
    var
        DateFilter: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(DateFilter);  // Dequeue variable.
        LibraryVariableStorage.Dequeue(No);  // Dequeue variable.
        VendorTotalBalance.Vendor.SetFilter("No.", No);
        VendorTotalBalance.Vendor.SetFilter("Date Filter", Format(DateFilter));
        VendorTotalBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATAdvNotAccProofReqPageHandler(var GLVATReconciliation: TestRequestPage "G/L - VAT Reconciliation")
    var
        PeriodSelection: Enum "VAT Statement Report Period Selection";
    begin
        GLVATReconciliation.StartDate.SetValue(Format(WorkDate()));  // Setting value for control Start Date.
        GLVATReconciliation.EndDateReq.SetValue(Format(WorkDate()));  // Setting value for control End Date.
        GLVATReconciliation.PeriodSelection.SetValue(Format(PeriodSelection::"Within Period"));  // Setting value for control Period Selection.
        GLVATReconciliation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(QuestionText: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

