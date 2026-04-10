codeunit 144009 "ERM VAT Agent"
{
    // // [FEATURE] [Purchase] [VAT Agent]
    // PS24788 VAT Agent
    // 
    // TEST FUNCTION NAME                           TFS ID
    // ApplyPartialVATAgentPmtToInvoice             326656

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        WrongValueErr: Label 'Wrong value in table %1, entry no. %2';
        LibrarySales: Codeunit "Library - Sales";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRUReports: Codeunit "Library RU Reports";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        VendorBalanceNotZeroErr: Label 'Vendor balance is not zero.';
        WrongGenJnlLineCountErr: Label 'Wrong general journal line count.';
        PmtAmtNotEqualInvAmtErr: Label 'Payment amount is not equal invoice amount.';
        VATEntryNoCompletelyRealizedErr: Label 'VAT entry is not completely realized.';
        RowDoesNotExistErr: Label 'The row does not exist on the TestPage';
        IncorrectAmountSignErr: Label 'Amount must be greater than zero.';

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineAFterSuggestVendorPayments()
    var
        VendorNo: Code[20];
        GLAccountNo: Code[20];
    begin
        SetupEnvironment(VendorNo, GLAccountNo);
        CreatePostPurchInvoice(VendorNo, WorkDate(), GLAccountNo, 100);
        SuggestVATAgentPayments(VendorNo, GetNextDocNo());
        VerifyGenJnlLineCount(2);
        VerifyPaymentAndInvoiceAmounts(VendorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostVATAgentPaymentAfterSuggestVendPmt()
    var
        VendorNo: Code[20];
        GLAccountNo: Code[20];
    begin
        SetupEnvironment(VendorNo, GLAccountNo);
        SetVendInternalFundsSetup(VendorNo);
        ModifyVATPostingSetup(VendorNo, GLAccountNo);
        PostApplyVATAgentPmtToInvoice(VendorNo, GLAccountNo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyVATAgentPmtToInvoice()
    var
        VendorNo: Code[20];
        GLAccountNo: Code[20];
    begin
        SetupEnvironment(VendorNo, GLAccountNo);
        PostApplyVATAgentPmtToInvoice(VendorNo, GLAccountNo, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPartialVATAgentPmtToInvoice()
    var
        GLAccountNo: Code[20];
        VendorNo: Code[20];
        PurchDocNo: Code[20];
        PaymentDocNo: Code[20];
        InvDocNo: Code[20];
        PurchVATAccNo: Code[20];
        PurchVATUnrealAccNo: Code[20];
        PmtDate: Date;
        InvAmount: Decimal;
        PmtAmount: Decimal;
        PmtApplAmount: Decimal;
    begin
        SetupEnvironment(VendorNo, GLAccountNo);
        SetVendInternalFundsSetup(VendorNo);
        InvAmount := LibraryRandom.RandDec(100, 2);
        PmtDate := CalcDate('<1Y>', WorkDate());
        PmtAmount := Round(InvAmount / 3);
        PmtApplAmount := Round(PmtAmount / 3);
        PurchDocNo := CreateReleasePurchInvoice(VendorNo, PmtDate, GLAccountNo, InvAmount);
        PaymentDocNo := CreatePostPrepayment(VendorNo, PurchDocNo, PmtAmount);
        InvDocNo := PostPurchInvoice(PurchDocNo);
        ApplyPostVendPaymentToInvoice(PaymentDocNo, InvDocNo, -PmtApplAmount);
        GetPurchVATAccountNoAndUnrealAccNo(PurchVATAccNo, PurchVATUnrealAccNo, VendorNo);
        VerifyCorrespEntry(PmtDate, PurchVATAccNo, PurchVATUnrealAccNo, CalcExpectedAmount(InvDocNo, PmtApplAmount));
    end;

    local procedure PostApplyVATAgentPmtToInvoice(VendorNo: Code[20]; GLAccountNo: Code[20]; ApplyEntries: Boolean)
    var
        InvNo: Code[20];
        PmtNo: Code[20];
    begin
        InvNo := CreatePostPurchInvoice(VendorNo, WorkDate(), GLAccountNo, 100);
        SuggestVATAgentPayments(VendorNo, GetNextDocNo());
        PmtNo := PostVATAgentPayment(VendorNo);
        if ApplyEntries then
            ApplyVendLedgEntriesAndVerifyClosedState(VendorNo, InvNo, PmtNo);

        VerifyZeroVendorBalance(VendorNo);
        VerifyMoreThanFourGLEntry(VendorNo);
        VerifyZeroRealizedVATEntry(VendorNo);
        VerifyUnrealizedVATEntry(VendorNo, 3000, 540);
        PostTaxAuthorityPayment();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxAuthIsNotShownOnVendorList()
    var
        Vendor: Record Vendor;
        VendorList: TestPage "Vendor List";
    begin
        // [FEATURE] [Tax Authority]
        // [SCENARIO 375181] Tax Authority is not shown on Vendor List page

        Initialize();
        // [GIVEN] Vendor "X" with "Vendor Type" = "Tax Authority"
        Vendor.Get(LibraryPurchase.CreateVendorTaxAuthority());
        VendorList.OpenView();

        // [WHEN] Open "Vendor List" page
        asserterror VendorList.GotoRecord(Vendor);

        // [THEN] There is no Vendor "X" on the page
        Assert.ExpectedError(RowDoesNotExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintFacturaInvoiceForVATAgentWithPrepayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvLine: Record "Purch. Inv. Line";
        LocalReportMgt: Codeunit "Local Report Management";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        PurchInvNo: Code[20];
        InvAmount: Decimal;
        FileName: Text;
    begin
        // [FEATURE] [Prepayment]
        // [SCENARIO 377108] Print Posted Purchase Factura-Invoice report for VAT Agent of Non-resident type with Prepayment
        Initialize();

        // [GIVEN] Vendor VAT Agent with Non-Resident type
        SetupEnvironment(VendorNo, GLAccountNo);
        SetVendInternalFundsSetup(VendorNo);

        // [GIVEN] Purchase Invoice with G/L Account line = "X": Amount = 100 and VAT = 18%
        InvAmount := LibraryRandom.RandDec(100, 2);
        PurchInvNo := CreateReleasePurchInvoice(VendorNo, WorkDate(), GLAccountNo, InvAmount);

        // [GIVEN] Post Prepayment for the Invoice in Gen Journal Line with Amount = 50
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo, InvAmount / 2);
        GenJournalLine.Validate(Prepayment, true);
        GenJournalLine.Validate("Prepayment Document No.", PurchInvNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Print in LCY report Pstd. Purch. Factura-Invoice
        RunPstdPurchFacturaInvoiceReport(PurchInvLine, VendorNo);

        // [THEN] Prepayment InvoiceNo is printed
        FileName := LibraryReportValidation.GetFileName();
        LibraryRUReports.VerifyFactura_DocNo(FileName, PurchInvLine."Document No.");

        // [THEN] Line for G/L Account No "X" is printed: Quantity and Price with dashes
        LibraryRUReports.VerifyFactura_ItemNo(FileName, GLAccountNo, 0);
        LibraryRUReports.VerifyFactura_Qty(FileName, '-', 0);
        LibraryRUReports.VerifyFactura_Price(FileName, '-', 0);
        // [THEN] Amount without VAT is printed '50,00'
        LibraryRUReports.VerifyFactura_Amount(FileName, LocalReportMgt.FormatReportValue(PurchInvLine."Amount (LCY)", 2), 0);
        // [THEN] VAT Percent is printed '18/118'
        LibraryRUReports.VerifyFactura_VATPct(FileName, Format(PurchInvLine."VAT %") + '/' + Format(100 + PurchInvLine."VAT %"), 0);
        // [THEN] VAT Amount is printed '9,00'
        LibraryRUReports.VerifyFactura_VATAmount(
          FileName, LocalReportMgt.FormatReportValue(PurchInvLine."Amount Including VAT (LCY)" - PurchInvLine."Amount (LCY)", 2), 0);
        // [THEN] Amount including VAT is printed '59,00'
        LibraryRUReports.VerifyFactura_AmountInclVAT(
          FileName, LocalReportMgt.FormatReportValue(PurchInvLine."Amount Including VAT (LCY)", 2), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsVATAgentVendor_Positive()
    var
        Vendor: Record Vendor;
        LocalReportManagement: Codeunit "Local Report Management";
        CVType: Option Vendor,Customer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] COD 12401 LocalReportManagement.IsVATAgentVendor() returns TRUE in case of VAT Agent vendor
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Agent", true);
        Vendor.Modify();

        Assert.IsTrue(
          LocalReportManagement.IsVATAgentVendor(Vendor."No.", CVType::Vendor),
          Vendor.FieldCaption("VAT Agent"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsVATAgentVendor_Negative()
    var
        Vendor: Record Vendor;
        LocalReportManagement: Codeunit "Local Report Management";
        CVType: Option Vendor,Customer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] COD 12401 LocalReportManagement.IsVATAgentVendor() returns FALSE in case of non-VAT Agent vendor
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);

        Assert.IsFalse(
          LocalReportManagement.IsVATAgentVendor(Vendor."No.", CVType::Vendor),
          Vendor.FieldCaption("VAT Agent"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsVATAgentVendor_Negative_Customer()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        LocalReportManagement: Codeunit "Local Report Management";
        CVType: Option Vendor,Customer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] COD 12401 LocalReportManagement.IsVATAgentVendor() returns FALSE in case of customer
        Initialize();

        LibrarySales.CreateCustomer(Customer);

        Assert.IsFalse(
          LocalReportManagement.IsVATAgentVendor(Customer."No.", CVType::Customer),
          Vendor.FieldCaption("VAT Agent"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedger_ApplyPaymentToInvoice()
    var
        Vendor: Record Vendor;
        PaymentAmount: Decimal;
        PaymentExternalDocNo: Code[20];
        VATLedgerCode: Code[20];
    begin
        // [FEATURE] [Sales VAT Ledger]
        // [SCENARIO 379397] Sales VAT ledger is created correctly when payment applied to invoice
        Initialize();

        // [GIVEN] Applied payment with external doc no. "EXTDOCNO" to invoice
        CreatePostApplyVATAgentPaymentToInvoice(Vendor, PaymentAmount, PaymentExternalDocNo);

        // [WHEN] VAT Sales Ledger is being created
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), '');

        // [THEN] Sales VAT ledger line created with proper amount and External Document No. "EXTDOCNO"
        VerifyVATLedgerLine(
          Vendor."No.", VATLedgerCode, PaymentAmount, PaymentExternalDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedger_ApplyInvoiceToPayment()
    var
        Vendor: Record Vendor;
        PaymentAmount: Decimal;
        PaymentExternalDocNo: Code[20];
        VATLedgerCode: Code[20];
    begin
        // [FEATURE] [Sales VAT Ledger]
        // [SCENARIO 379397] Sales VAT ledger is created correctly when invoice applied to payment
        Initialize();

        // [GIVEN] Applied invoice to payment with external doc no. "EXTDOCNO"
        CreatePostApplyVATAgentInvoiceToPayment(Vendor, PaymentAmount, PaymentExternalDocNo);

        // [WHEN] VAT Sales Ledger is being created
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), '');

        // [THEN] Sales VAT ledger line created with proper amount and External Document No. "EXTDOCNO"
        VerifyVATLedgerLine(
          Vendor."No.", VATLedgerCode, PaymentAmount, PaymentExternalDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedger_ApplyPaymentToInvoice()
    var
        Vendor: Record Vendor;
        PaymentAmount: Decimal;
        PaymentExternalDocNo: Code[20];
        VATLedgerCode: Code[20];
    begin
        // [FEATURE] [Purchase VAT Ledger]
        // [SCENARIO 379397] Purchase VAT ledger is created correctly when payment applied to invoice
        Initialize();

        // [GIVEN] Applied payment with external doc no. "EXTDOCNO" to invoice
        CreatePostApplyVATAgentPaymentToInvoice(Vendor, PaymentAmount, PaymentExternalDocNo);

        // [WHEN] VAT Purchase Ledger is being created
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(WorkDate(), WorkDate(), '', true, false);

        // [THEN] Purchase VAT ledger line created with proper Amount, Document No. from VAT Agent Invoice and External Document No. "EXTDOCNO"
        VerifyVATLedgerLine(
          Vendor."No.", VATLedgerCode, PaymentAmount, PaymentExternalDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedger_ApplyInvoiceToPayment()
    var
        Vendor: Record Vendor;
        PaymentAmount: Decimal;
        PaymentExternalDocNo: Code[20];
        VATLedgerCode: Code[20];
    begin
        // [FEATURE] [Purchase VAT Ledger]
        // [SCENARIO 379397] Purchase VAT ledger is created correctly when invoice applied to payment
        Initialize();

        // [GIVEN] Applied invoice to payment with external doc no. "EXTDOCNO"
        CreatePostApplyVATAgentInvoiceToPayment(Vendor, PaymentAmount, PaymentExternalDocNo);

        // [WHEN] VAT Purchase Ledger is being created
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(WorkDate(), WorkDate(), '', true, false);

        // [THEN] Purchase VAT ledger line created with proper Amount, Document No. from VAT Agent Invoice and External Document No. "EXTDOCNO"
        VerifyVATLedgerLine(
          Vendor."No.", VATLedgerCode, PaymentAmount, PaymentExternalDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedger_PrepaymentNotApplied()
    var
        Vendor: Record Vendor;
        PaymentAmount: Decimal;
        VATLedgerCode: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase VAT Ledger]
        // [SCENARIO 379454] Not applied prepayment is not showed in the purchase VAT ledger
        Initialize();

        // [GIVEN] Released invoice
        CreateReleaseVATAgentInvoice(Vendor, InvoiceNo, 18, PaymentAmount);

        // [GIVEN] Posted prepayment
        CreatePostPrepayment(Vendor."No.", InvoiceNo, PaymentAmount);

        // [WHEN] VAT Purchase Ledger is being created
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(WorkDate(), WorkDate(), '', true, false);

        // [THEN] Purchase VAT ledger line is not created
        VerifyPurchVATLedgerLineDoesNotExist(
          Vendor."No.", VATLedgerCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedger_PrepaymentApplied_VAT18()
    var
        Vendor: Record Vendor;
        PaymentAmount: Decimal;
        VATLedgerCode: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Purchase VAT Ledger]
        // [SCENARIO 379454] Applied prepayment for 18% is showed in the purchase VAT ledger
        Initialize();

        // [GIVEN] Vendor with VAT Agent VAT Posting Setup VAT % = 18
        // [GIVEN] Released invoice
        CreateReleaseVATAgentInvoice(Vendor, InvoiceNo, 18, PaymentAmount);

        // [GIVEN] Posted prepayment
        PaymentNo := CreatePostPrepayment(Vendor."No.", InvoiceNo, PaymentAmount);

        // [GIVEN] Posted invoice applied to prepayment
        PostInvoiceAndApplyToPrepayment(InvoiceNo, PaymentNo);

        // [WHEN] VAT Purchase Ledger is being created
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(WorkDate(), WorkDate(), '', true, false);

        // [THEN] Purchase VAT ledger line is created with Amount in currency = "Payment Amount" + "VAT Amount"
        VerifyPrepaymentVATLedgerLine(Vendor."No.", VATLedgerCode, PaymentAmount, 18);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedger_PrepaymentApplied_VAT10()
    var
        Vendor: Record Vendor;
        PaymentAmount: Decimal;
        VATLedgerCode: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Purchase VAT Ledger]
        // [SCENARIO 379454] Applied prepayment for VAT 10% is showed in the purchase VAT ledger
        Initialize();

        // [GIVEN] Vendor with VAT Agent VAT Posting Setup VAT % = 10
        // [GIVEN] Released invoice
        CreateReleaseVATAgentInvoice(Vendor, InvoiceNo, 10, PaymentAmount);

        // [GIVEN] Posted prepayment
        PaymentNo := CreatePostPrepayment(Vendor."No.", InvoiceNo, PaymentAmount);

        // [GIVEN] Post released invoice
        InvoiceNo := PostPurchInvoice(InvoiceNo);

        // [GIVEN] Apply invoice to payment
        LibraryERM.ApplyVendorLedgerEntries(
          "Gen. Journal Document Type"::Invoice, "Gen. Journal Document Type"::Payment, InvoiceNo, PaymentNo);

        // [WHEN] VAT Purchase Ledger is being created
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(WorkDate(), WorkDate(), '', true, false);

        // [THEN] Purchase VAT ledger line is created with Amount in currency = "Payment Amount" + "VAT Amount"
        VerifyPrepaymentVATLedgerLine(Vendor."No.", VATLedgerCode, PaymentAmount, 10);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedger_PrepaymentNotApplied_VAT18()
    var
        Vendor: Record Vendor;
        PaymentAmount: Decimal;
        VATLedgerCode: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales VAT Ledger]
        // [SCENARIO 379454] Not applied prepayment for 18% is showed in the sales VAT ledger
        Initialize();

        // [GIVEN] Vendor with VAT Agent VAT Posting Setup VAT % = 18
        // [GIVEN] Released invoice
        CreateReleaseVATAgentInvoice(Vendor, InvoiceNo, 18, PaymentAmount);

        // [GIVEN] Posted prepayment
        CreatePostPrepayment(Vendor."No.", InvoiceNo, PaymentAmount);

        // [WHEN] VAT Sales Ledger is being created
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), '');

        // [THEN] Sales VAT ledger line is created with Amount in currency = "Payment Amount" + "VAT Amount" and positive LCY amounts
        VerifyPrepaymentVATLedgerLine(Vendor."No.", VATLedgerCode, PaymentAmount, 18);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedger_PrepaymentNotApplied_VAT10()
    var
        Vendor: Record Vendor;
        PaymentAmount: Decimal;
        VATLedgerCode: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales VAT Ledger]
        // [SCENARIO 379454] Not applied prepayment for VAT 10% is showed in the sales VAT ledger
        Initialize();

        // [GIVEN] Vendor with VAT Agent VAT Posting Setup VAT % = 10
        // [GIVEN] Released invoice
        CreateReleaseVATAgentInvoice(Vendor, InvoiceNo, 10, PaymentAmount);

        // [GIVEN] Posted prepayment
        CreatePostPrepayment(Vendor."No.", InvoiceNo, PaymentAmount);

        // [WHEN] VAT Sales Ledger is being created
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), '');

        // [THEN] Sales VAT ledger line is created with Amount in currency = "Payment Amount" + "VAT Amount" and positive LCY amounts
        VerifyPrepaymentVATLedgerLine(Vendor."No.", VATLedgerCode, PaymentAmount, 10);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedger_PrepaymentApplied_VAT18()
    var
        Vendor: Record Vendor;
        PaymentAmount: Decimal;
        VATLedgerCode: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Sales VAT Ledger]
        // [SCENARIO 379454] Applied prepayment for 18% is showed in the sales VAT ledger
        Initialize();

        // [GIVEN] Vendor with VAT Agent VAT Posting Setup VAT % = 18
        // [GIVEN] Released invoice
        CreateReleaseVATAgentInvoice(Vendor, InvoiceNo, 18, PaymentAmount);

        // [GIVEN] Posted prepayment
        PaymentNo := CreatePostPrepayment(Vendor."No.", InvoiceNo, PaymentAmount);

        // [GIVEN] Posted invoice applied to prepayment
        PostInvoiceAndApplyToPrepayment(InvoiceNo, PaymentNo);

        // [WHEN] VAT Sales Ledger is being created
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), '');

        // [THEN] Sales VAT ledger line is created with Amount in currency = "Payment Amount" + "VAT Amount" and positive LCY amounts
        VerifyPrepaymentVATLedgerLine(Vendor."No.", VATLedgerCode, PaymentAmount, 18);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedger_PrepaymentApplied_VAT10()
    var
        Vendor: Record Vendor;
        PaymentAmount: Decimal;
        VATLedgerCode: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Sales VAT Ledger]
        // [SCENARIO 379454] Applied prepayment for VAT 10% is showed in the sales VAT ledger
        Initialize();

        // [GIVEN] Vendor with VAT Agent VAT Posting Setup VAT % = 10
        // [GIVEN] Released invoice
        CreateReleaseVATAgentInvoice(Vendor, InvoiceNo, 10, PaymentAmount);

        // [GIVEN] Posted prepayment
        PaymentNo := CreatePostPrepayment(Vendor."No.", InvoiceNo, PaymentAmount);

        // [GIVEN] Post released invoice
        InvoiceNo := PostPurchInvoice(InvoiceNo);

        // [GIVEN] Apply invoice to payment
        LibraryERM.ApplyVendorLedgerEntries(
          "Gen. Journal Document Type"::Invoice, "Gen. Journal Document Type"::Payment, InvoiceNo, PaymentNo);

        // [WHEN] VAT Sales Ledger is being created
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), '');

        // [THEN] Sales VAT ledger line is created with Amount in currency = "Payment Amount" + "VAT Amount" and positive LCY amounts
        VerifyPrepaymentVATLedgerLine(Vendor."No.", VATLedgerCode, PaymentAmount, 10);
    end;

    local procedure Initialize()
    var
        PurchSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if IsInitialized then
            exit;

        InitGenJnlBatch();
        LibraryERMCountryData.UpdateLocalData();
        SalesSetup.Get();
        PurchSetup.Get();
        PurchSetup."Posted VAT Agent Invoice Nos." := SalesSetup."Posted Invoice Nos.";
        PurchSetup.Modify();
        IsInitialized := true;
        Commit();
    end;

    local procedure InitGenJnlBatch()
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        if GenJnlBatch."No. Series" = '' then begin
            GenJnlBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
            GenJnlBatch.Modify(true);
        end;
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency."Realized Gains Acc." := LibraryERM.CreateGLAccountNo();
        Currency."Realized Losses Acc." := LibraryERM.CreateGLAccountNo();
        Currency."PD Bal. Gain/Loss Acc. (TA)" := LibraryERM.CreateGLAccountNo();
        Currency."Purch. PD Gains Acc. (TA)" := LibraryERM.CreateGLAccountNo();
        Currency."Purch. PD Losses Acc. (TA)" := LibraryERM.CreateGLAccountNo();
        Currency.Modify();
        exit(Currency.Code);
    end;

    local procedure CreateTaxAuthority(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Vendor Type", Vendor."Vendor Type"::"Tax Authority");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure PostPurchInvoice(PurchHeaderNo: Code[20]): Code[20]
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Get(PurchHeader."Document Type"::Invoice, PurchHeaderNo);
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure ReleasePurchInvoice(PurchHeaderNo: Code[20]): Code[20]
    var
        PurchHeader: Record "Purchase Header";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
    begin
        PurchHeader.Get(PurchHeader."Document Type"::Invoice, PurchHeaderNo);
        ReleasePurchDoc.PerformManualRelease(PurchHeader);
        exit(PurchHeaderNo);
    end;

    local procedure PostTaxAuthorityPayment()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJnlLine);
    end;

    local procedure PostVATAgentPayment(VendorNo: Code[20]): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
        PmtNo: Code[20];
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.SetRange("Account No.", VendorNo);
        GenJnlLine.FindFirst();
        PmtNo := GenJnlLine."Document No.";
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJnlLine);
        exit(PmtNo);
    end;

    local procedure CreatePostPrepayment(VendNo: Code[20]; ApplyDocNo: Code[20]; PayAmount: Decimal) DocNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJnlTemplate.Name,
            GenJnlBatch.Name, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendNo, 0);
        GenJournalLine.Validate(Prepayment, true);
        GenJournalLine.Validate("Prepayment Document No.", ApplyDocNo);
        GenJournalLine.Validate("External Document No.", ApplyDocNo);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", CreateBankAccount());
        GenJournalLine.Validate(Amount, PayAmount);
        GenJournalLine.Modify(true);
        DocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostPayment(VendNo: Code[20]; ExternalDocNo: Code[20]; InitialDocNo: Code[20]; var PayAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendNo, 0);
        GenJournalLine.Validate("External Document No.", ExternalDocNo);
        GenJournalLine.Validate("Initial Document No.", InitialDocNo);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", CreateBankAccount());
        GenJournalLine.Validate(Amount, PayAmount);
        GenJournalLine.Modify(true);
        PayAmount := GenJournalLine."Amount (LCY)";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePostPurchInvoice(VendNo: Code[20]; PostingDate: Date; GLAccountNo: Code[20]; Amount: Decimal): Code[20]
    var
        AmountInclVAT: Decimal;
    begin
        exit(PostPurchInvoice(CreatePurchInvoice(VendNo, PostingDate, GLAccountNo, Amount, AmountInclVAT)));
    end;

    local procedure CreateReleasePurchInvoice(VendNo: Code[20]; PostingDate: Date; GLAccountNo: Code[20]; Amount: Decimal): Code[20]
    var
        AmountInclVAT: Decimal;
    begin
        exit(ReleasePurchInvoice(CreatePurchInvoice(VendNo, PostingDate, GLAccountNo, Amount, AmountInclVAT)));
    end;

    local procedure CreatePurchInvoice(VendNo: Code[20]; PostingDate: Date; GLAccountNo: Code[20]; Amount: Decimal; var AmountInclVAT: Decimal): Code[20]
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, VendNo);
        PurchHeader.SetHideValidationDialog(true);
        PurchHeader.Validate("Posting Date", PostingDate);
        PurchHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccountNo, 1);
        PurchLine.Validate("Direct Unit Cost", Amount);
        PurchLine.Modify(true);
        AmountInclVAT := PurchLine."Amount Including VAT";
        exit(PurchHeader."No.");
    end;

    local procedure CreateCurrencyExchRate(CurrencyCode: Code[10]; StartingDate: Date; Rate: Decimal)
    var
        CurrencyExchRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchRate.Init();
        CurrencyExchRate."Currency Code" := CurrencyCode;
        CurrencyExchRate."Starting Date" := StartingDate;
        CurrencyExchRate."Exchange Rate Amount" := 1;
        CurrencyExchRate."Adjustment Exch. Rate Amount" := 1;
        CurrencyExchRate."Relational Exch. Rate Amount" := Rate;
        CurrencyExchRate."Relational Adjmt Exch Rate Amt" := Rate;
        CurrencyExchRate.Insert();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        exit(BankAccount."No.");
    end;

    local procedure CreatePostApplyVATAgentPaymentToInvoice(var Vendor: Record Vendor; var PaymentAmount: Decimal; var PaymentExternalDocNo: Code[20])
    var
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        CreatePostVATAgentInvoiceAndPayment(Vendor, PaymentAmount, InvoiceNo, PaymentNo, PaymentExternalDocNo);

        LibraryERM.ApplyVendorLedgerEntries(
          "Gen. Journal Document Type"::Payment, "Gen. Journal Document Type"::Invoice, PaymentNo, InvoiceNo);
    end;

    local procedure CreatePostApplyVATAgentInvoiceToPayment(var Vendor: Record Vendor; var PaymentAmount: Decimal; var PaymentExternalDocNo: Code[20])
    var
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        CreatePostVATAgentInvoiceAndPayment(Vendor, PaymentAmount, InvoiceNo, PaymentNo, PaymentExternalDocNo);

        LibraryERM.ApplyVendorLedgerEntries(
          "Gen. Journal Document Type"::Invoice, "Gen. Journal Document Type"::Payment, InvoiceNo, PaymentNo);
    end;

    local procedure CreatePostVATAgentInvoiceAndPayment(var Vendor: Record Vendor; var PaymentAmount: Decimal; var InvoiceNo: Code[20]; var PaymentNo: Code[20]; var PaymentExternalDocNo: Code[20])
    var
        VATPostingSetupNoVAT: Record "VAT Posting Setup";
        InvoiceAmount: Decimal;
        GLAccountNo: Code[20];
    begin
        // Create VAT agent vendor with unrealized VAT Posting Setup for VAT agent
        CreateVATAgentVendorWithPostingSetup(Vendor, VATPostingSetupNoVAT, 18);

        // Create and post invoice
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetupNoVAT, "General Posting Type"::" ");
        InvoiceAmount := LibraryRandom.RandDecInRange(500, 1000, 2);
        InvoiceNo := CreatePostPurchInvoice(Vendor."No.", WorkDate(), GLAccountNo, InvoiceAmount);

        // Create and post payment
        PaymentExternalDocNo := LibraryUtility.GenerateGUID();
        PaymentAmount := Round(InvoiceAmount / LibraryRandom.RandIntInRange(2, 5));
        PaymentNo := CreatePostPayment(Vendor."No.", PaymentExternalDocNo, InvoiceNo, PaymentAmount);
    end;

    local procedure CreateReleaseVATAgentInvoice(var Vendor: Record Vendor; var InvoiceNo: Code[20]; UnrealizedVATPercent: Decimal; var PaymentAmount: Decimal)
    var
        VATPostingSetupNoVAT: Record "VAT Posting Setup";
        InvoiceAmount: Decimal;
        AmountIncludingVAT: Decimal;
        GLAccountNo: Code[20];
    begin
        // Create VAT agent vendor with unrealized VAT Posting Setup for VAT agent
        CreateVATAgentVendorWithPostingSetup(Vendor, VATPostingSetupNoVAT, UnrealizedVATPercent);

        // Create and release invoice
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetupNoVAT, "General Posting Type"::" ");
        InvoiceAmount := LibraryRandom.RandDecInRange(500, 1000, 2);
        InvoiceNo := CreatePurchInvoice(Vendor."No.", WorkDate(), GLAccountNo, InvoiceAmount, AmountIncludingVAT);
        ReleasePurchInvoice(InvoiceNo);

        PaymentAmount := Round(InvoiceAmount / LibraryRandom.RandIntInRange(2, 5));
    end;

    local procedure CreateVATAgentVendorWithPostingSetup(var Vendor: Record Vendor; var VATPostingSetupNoVAT: Record "VAT Posting Setup"; UnrealizedVATPercent: Decimal)
    var
        VATBusPostGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        VATProdPostingGroupVATAgent: Record "VAT Product Posting Group";
        VATPostingSetupUnrealizedVAT: Record "VAT Posting Setup";
    begin
        // Create VAT Bus. Posting Group
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostGroup);

        // Create 2 VAT Prod. Posting Group
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroupVATAgent);

        // Create VAT Posting Setup 1 - 0% realized VAT
        LibraryERM.CreateVATPostingSetup(VATPostingSetupNoVAT, VATBusPostGroup.Code, VATProdPostingGroup.Code);

        // Create VAT Posting Setup 2 - 18% unrealized VAT
        CreateUnrealizedVATPostingSetup(
          VATPostingSetupUnrealizedVAT, VATBusPostGroup.Code, VATProdPostingGroupVATAgent.Code, UnrealizedVATPercent);

        // Create VAT Agent
        CreateVendorVATAgent(Vendor, VATBusPostGroup.Code, VATPostingSetupUnrealizedVAT."VAT Prod. Posting Group");
    end;

    local procedure CreateVendorVATAgent(var Vendor: Record Vendor; VATBusPostGroupCode: Code[20]; VATAgentProdPostingGroupCode: Code[20])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CreateCurrencyWithExchangeRate());
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostGroupCode);
        Vendor.Validate("VAT Agent", true);
        Vendor.Validate("VAT Agent Type", Vendor."VAT Agent Type"::"Non-resident");
        Vendor.Validate("VAT Payment Source Type", Vendor."VAT Payment Source Type"::"Internal Funds");
        Vendor.Validate("VAT Agent Prod. Posting Group", VATAgentProdPostingGroupCode);
        Vendor.Validate("Tax Authority No.", CreateTaxAuthority());
        Vendor.Modify(true);
    end;

    local procedure CreateCurrencyWithExchangeRate() CurrencyCode: Code[10]
    begin
        CurrencyCode := CreateCurrency();
        CreateCurrencyExchRate(CurrencyCode, WorkDate(), LibraryRandom.RandDec(100, 2));
        CreateCurrencyExchRate(CurrencyCode, CalcDate('<1Y>', WorkDate()), LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateUnrealizedVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostGroupCode: Code[20]; VATProdPostGroupCode: Code[20]; VATPercent: Decimal)
    begin
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostGroupCode, VATProdPostGroupCode);
        VATPostingSetup.Validate("VAT Identifier", VATProdPostGroupCode);
        VATPostingSetup.Validate("VAT %", VATPercent);
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify();
    end;

    local procedure ApplyPostVendPaymentToInvoice(PaymentDocNo: Code[20]; InvoiceDocNo: Code[20]; AmountToApply: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        ApplyAndPostVendorEntry(
          PaymentDocNo, InvoiceDocNo,
          VendorLedgerEntry."Document Type"::Payment, VendorLedgerEntry."Document Type"::Invoice, AmountToApply);
    end;

    local procedure ApplyAndPostVendorEntry(DocNoFrom: Code[20]; DocNoTo: Code[20]; DocTypeFrom: Enum "Gen. Journal Document Type"; DocTypeTo: Enum "Gen. Journal Document Type"; AmountToApply: Decimal)
    var
        VendorLedgerEntryFrom: Record "Vendor Ledger Entry";
        VendorLedgerEntryTo: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntryFrom, DocTypeFrom, DocNoFrom);
        VendorLedgerEntryFrom.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntryFrom, VendorLedgerEntryFrom."Remaining Amount");

        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntryTo, DocTypeTo, DocNoTo);
        VendorLedgerEntryTo.FindFirst();
        VendorLedgerEntryTo.Validate("Amount to Apply", AmountToApply);
        VendorLedgerEntryTo.Modify(true);

        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntryTo);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntryFrom);
    end;

    local procedure ModifyVATPostingSetup(VendorNo: Code[20]; GLAccountNo: Code[20])
    var
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Vendor.Get(VendorNo);
        GLAccount.Get(GLAccountNo);
        VATPostingSetup.Get(Vendor."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup."Unrealized VAT Type" := VATPostingSetup."Unrealized VAT Type"::" ";
        VATPostingSetup.Modify();
    end;

    local procedure ClearGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.DeleteAll();
        GenJnlLine."Journal Template Name" := GenJnlTemplate.Name;
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
    end;

    local procedure GetNextDocNo() UseDocNo: Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        UseDocNo := NoSeries.PeekNextNo(GenJnlBatch."No. Series");
    end;

    local procedure GetLastInvNo(VendorNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Reset();
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvHeader.FindLast();
        exit(PurchInvHeader."No.");
    end;

    local procedure GetPurchVATAccountNoAndUnrealAccNo(var VATAccNo: Code[20]; var VATUnrealAccNo: Code[20]; VendNo: Code[20])
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Vendor.Get(VendNo);
        VATPostingSetup.Get(Vendor."VAT Bus. Posting Group", Vendor."VAT Agent Prod. Posting Group");
        VATAccNo := VATPostingSetup."Purchase VAT Account";
        VATUnrealAccNo := VATPostingSetup."Purch. VAT Unreal. Account";
    end;

    local procedure GetVATAgentInvoiceNo(VendorNo: Code[20]): Code[20]
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATAgentInvoiceVATEntry(VATEntry, VendorNo);
        exit(VATEntry."Document No.");
    end;

    local procedure GetExpectedPrepaymentPurchVATLedgerAmountFCY(PaymentAmount: Decimal; VATPct: Decimal): Decimal
    begin
        exit(Round(PaymentAmount * (VATPct + 100) / 100));
    end;

    local procedure FindVATAgentInvoiceVATEntry(var VATEntry: Record "VAT Entry"; VendorNo: Code[20])
    begin
        VATEntry.SetFilter("Bill-to/Pay-to No.", VendorNo);
        VATEntry.SetRange("VAT Agent", true);
        VATEntry.SetFilter("Unrealized Base", '<>0');
        VATEntry.FindFirst();
    end;

    local procedure SuggestVATAgentPayments(VendNo: Code[20]; DocNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        SuggestVendPmt: Report "Suggest Vendor Payments";
    begin
        ClearGenJnlLine(GenJnlLine);
        Vendor.SetRange("No.", VendNo);
        Clear(SuggestVendPmt);
        SuggestVendPmt.UseRequestPage(false);
        SuggestVendPmt.SetTableView(Vendor);
        SuggestVendPmt.SetGenJnlLine(GenJnlLine);
        SuggestVendPmt.InitializeRequest(
          CalcDate('<CM>', WorkDate()), false, 0, false, WorkDate(), DocNo, false,
          GenJnlLine."Bal. Account Type"::"Bank Account", CreateBankAccount(), GenJnlLine."Bank Payment Type"::" ");
        SuggestVendPmt.InitVATAgentPayment(true);
        SuggestVendPmt.SetHideMessage(true);
        SuggestVendPmt.Run();
    end;

    local procedure SetVendInternalFundsSetup(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor."VAT Payment Source Type" := Vendor."VAT Payment Source Type"::"Internal Funds";
        Vendor.Modify();
    end;

    local procedure SetupEnvironment(var VendorNo: Code[20]; var GLAccountNo: Code[20])
    var
        VATProdPostingGr: Record "VAT Product Posting Group";
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        CurrencyCode: Code[10];
    begin
        Initialize();
        CurrencyCode := CreateCurrency();
        CreateCurrencyExchRate(CurrencyCode, WorkDate(), 30);
        CreateCurrencyExchRate(CurrencyCode, CalcDate('<1Y>', WorkDate()), 28);

        LibraryERM.CreateUnrealizedVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("VAT %", 18);
        VATPostingSetup.Modify(true);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" ");
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");

        GLAccount.Get(GLAccountNo);
        VATProdPostingGr.Get(LibraryERM.CreateRelatedVATPostingSetup(GLAccount));

        Vendor.Get(VendorNo);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Validate("VAT Agent", true);
        Vendor.Validate("VAT Agent Type", Vendor."VAT Agent Type"::"Non-resident");
        Vendor.Validate("VAT Agent Prod. Posting Group", VATProdPostingGr.Code);
        Vendor.Validate("Tax Authority No.", CreateTaxAuthority());
        Vendor.Modify(true);
    end;

    local procedure ApplyVendLedgEntriesAndVerifyClosedState(VendNo: Code[20]; InvNo: Code[20]; PmtNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.ApplyVendorLedgerEntry(
            VendLedgEntry."Document Type"::Invoice, InvNo,
            VendLedgEntry."Document Type"::Payment, PmtNo);

        VendLedgEntry.Reset();
        VendLedgEntry.SetRange("Vendor No.", VendNo);
        if VendLedgEntry.FindSet() then
            repeat
                Assert.IsFalse(VendLedgEntry.Open, StrSubstNo(WrongValueErr, VendLedgEntry.TableCaption(), VendLedgEntry.FieldCaption(Open)));
            until VendLedgEntry.Next() = 0;
    end;

    local procedure PostInvoiceAndApplyToPrepayment(var InvoiceNo: Code[20]; PaymentNo: Code[20])
    begin
        // [GIVEN] Post released invoice
        InvoiceNo := PostPurchInvoice(InvoiceNo);

        // [GIVEN] Apply invoice to payment
        LibraryERM.ApplyVendorLedgerEntries(
          "Gen. Journal Document Type"::Invoice, "Gen. Journal Document Type"::Payment, InvoiceNo, PaymentNo);
    end;

    local procedure RunPstdPurchFacturaInvoiceReport(var PurchInvLine: Record "Purch. Inv. Line"; VendorNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PstdPurchFacturaInvoice: Report "Pstd. Purch. Factura-Invoice";
        FileName: Text;
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvHeader.FindFirst();
        PurchInvHeader.SetRecFilter();
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();
        Commit();

        LibraryReportValidation.SetFileName(PurchInvHeader."No.");
        FileName := LibraryReportValidation.GetFileName();
        PstdPurchFacturaInvoice.SetTableView(PurchInvHeader);
        PstdPurchFacturaInvoice.InitializeRequest(1, 1);
        PstdPurchFacturaInvoice.SetFileNameSilent(FileName);
        PstdPurchFacturaInvoice.UseRequestPage(false);
        PstdPurchFacturaInvoice.Run();
    end;

    local procedure CalcExpectedAmount(DocNo: Code[20]; BaseAmount: Decimal): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ExchangeRate: Decimal;
    begin
        PurchInvHeader.Get(DocNo);
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();
        VATPostingSetup.Get(PurchInvLine."VAT Bus. Posting Group", PurchInvLine."VAT Prod. Posting Group");
        ExchangeRate := CurrExchRate.ExchangeRate(WorkDate(), PurchInvHeader."Currency Code");
        exit(
          Round(
            CurrExchRate.ExchangeAmtFCYToLCY(WorkDate(), PurchInvHeader."Currency Code", BaseAmount, ExchangeRate) *
            PurchInvLine."VAT %" / 100));
    end;

    local procedure VerifyCorrespEntry(PostingDate: Date; DebitAccNo: Code[20]; CreditAccNo: Code[20]; ExpAmount: Decimal)
    var
        GLCorrEntry: Record "G/L Correspondence Entry";
    begin
        GLCorrEntry.SetRange("Posting Date", PostingDate);
        GLCorrEntry.SetRange("Debit Account No.", DebitAccNo);
        GLCorrEntry.SetRange("Credit Account No.", CreditAccNo);
        GLCorrEntry.FindLast();
        Assert.AreEqual(ExpAmount, GLCorrEntry.Amount, '');
    end;

    local procedure VerifyZeroVendorBalance(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.CalcFields("Balance (LCY)");
        Assert.AreEqual(0, Vendor."Balance (LCY)", VendorBalanceNotZeroErr);
    end;

    local procedure VerifyGenJnlLineCount(ExpectedCount: Integer)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        Assert.AreEqual(ExpectedCount, GenJnlLine.Count, WrongGenJnlLineCountErr);
    end;

    local procedure VerifyPaymentAndInvoiceAmounts(VendorNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.SetRange("Account No.", VendorNo);
        GenJnlLine.FindFirst();
        PurchInvHeader.Get(GenJnlLine."Initial Document No.");
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        Assert.AreEqual(GenJnlLine.Amount, PurchInvHeader.Amount, PmtAmtNotEqualInvAmtErr);
    end;

    local procedure VerifyMoreThanFourGLEntry(VendorNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Source Type", "Source No.");
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::Vendor);
        GLEntry.SetRange("Source No.", VendorNo);
        Assert.IsTrue(GLEntry.Count >= 4, WrongGenJnlLineCountErr);
    end;

    local procedure VerifyZeroRealizedVATEntry(VendorNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey(Type, "Bill-to/Pay-to No.");
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("Bill-to/Pay-to No.", VendorNo);
        VATEntry.FindFirst();
        Assert.AreEqual(0, VATEntry."Remaining Unrealized Amount", VATEntryNoCompletelyRealizedErr);
        Assert.AreEqual(0, VATEntry."Remaining Unrealized Base", VATEntryNoCompletelyRealizedErr);
    end;

    local procedure VerifyUnrealizedVATEntry(VendorNo: Code[20]; UnrealizedBase: Decimal; UnrealizedAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", GetLastInvNo(VendorNo));
        VATEntry.FindFirst();
        Assert.AreEqual(UnrealizedBase, VATEntry."Unrealized Base", StrSubstNo(WrongValueErr, VATEntry.TableCaption(), VATEntry.FieldCaption("Unrealized Base")));
        Assert.AreEqual(UnrealizedAmount, VATEntry."Unrealized Amount", StrSubstNo(WrongValueErr, VATEntry.TableCaption(), VATEntry.FieldCaption("Unrealized Amount")));
    end;

    local procedure VerifyVATLedgerLine(VendorNo: Code[20]; VATLedgerCode: Code[20]; PaymentAmount: Decimal; PaymentExternalDocNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.SetRange(Code, VATLedgerCode);
        VATLedgerLine.SetRange("C/V No.", VendorNo);
        VATLedgerLine.FindFirst();
        VATLedgerLine.TestField(Base18, PaymentAmount);
        VATLedgerLine.TestField("Document No.", GetVATAgentInvoiceNo(VendorNo));
        VATLedgerLine.TestField("External Document No.", PaymentExternalDocNo);
    end;

    local procedure VerifyPrepaymentVATLedgerLine(VendorNo: Code[20]; VATLedgerCode: Code[20]; PaymentAmount: Decimal; VATPercent: Decimal)
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATEntry: Record "VAT Entry";
    begin
        FindVATAgentInvoiceVATEntry(VATEntry, VendorNo);
        VATLedgerLine.SetRange(Code, VATLedgerCode);
        VATLedgerLine.SetRange("C/V No.", VendorNo);
        VATLedgerLine.FindFirst();
        VATLedgerLine.TestField(Amount, GetExpectedPrepaymentPurchVATLedgerAmountFCY(PaymentAmount, VATPercent));
        VATLedgerLine.TestField("Document No.", VATEntry."Document No.");
        case VATPercent of
            10:
                begin
                    Assert.IsTrue(VATLedgerLine.Amount10 > 0, IncorrectAmountSignErr);
                    VATLedgerLine.TestField(Base10, VATEntry."Unrealized Amount" + VATEntry."Unrealized Base");
                end;
            18:
                begin
                    Assert.IsTrue(VATLedgerLine.Amount18 > 0, IncorrectAmountSignErr);
                    VATLedgerLine.TestField(Base18, VATEntry."Unrealized Amount" + VATEntry."Unrealized Base");
                end;
        end;
    end;

    local procedure VerifyPurchVATLedgerLineDoesNotExist(VendorNo: Code[20]; VATLedgerCode: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.SetRange(Type, VATLedgerLine.Type::Purchase);
        VATLedgerLine.SetRange(Code, VATLedgerCode);
        VATLedgerLine.SetRange("C/V No.", VendorNo);
        Assert.RecordIsEmpty(VATLedgerLine);
    end;
}

