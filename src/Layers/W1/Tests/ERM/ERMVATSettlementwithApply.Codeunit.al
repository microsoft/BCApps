codeunit 134008 "ERM VAT Settlement with Apply"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "VAT Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Sales]
        isInitialized := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        AdditionalCurrencyError: Label 'Additional Currency Amount must be %1.';
        UnappliedError: Label '%1 %2 field must be true after Unapply entries.';
        UnrealizedVATType: Option " ",Percentage,First,Last,"First (Fully Paid)","Last (Fully Paid)";
        PostingGroupsErr: Label 'Posting Groups are missing for unapplied G/L Entry with Payment Discount Account.';
        IncorrectVATEntryCountErr: Label 'Incorrect count of VAT Entries.';

    [Test]
    [Scope('OnPrem')]
    procedure ApplyAndVatSettlement()
    var
        VatPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CalcandPostVATSettlement: Report "Calc. and Post VAT Settlement";
        FilePath: Text[1024];
    begin
        // Covers documents TC_ID= 122631,122632,122633.
        // Check that VAT Settlement Report has been generated and saved with some data after apply General Journal Lines.

        // Setup.
        Initialize();

        // Create, Post and Apply General journal Lines.
        PostApplyGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment,
          LibraryRandom.RandInt(500));

        VatPostingSetup.SetFilter("VAT %", '>0');
        VatPostingSetup.FindLast();
        CalcandPostVATSettlement.SetTableView(VatPostingSetup);
        CalcandPostVATSettlement.InitializeRequest(
          WorkDate(), WorkDate(), WorkDate(), GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", false, false);
        CalcandPostVATSettlement.UseRequestPage(false);

        FilePath := TemporaryPath + Format(VatPostingSetup.TableName) + '.xlsx';
        CalcandPostVATSettlement.SaveAsExcel(FilePath);

        // Verify: Verify that Saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);

        // Cleanup: Delete Additional Currency and Unrealized VAT set to False from General Ledger Setup and Unrealized VAT type from
        // VAT Posting Setup.
        ModifyVATPostingSetup(UnrealizedVATType::" ");
        ModifyGeneralLedegerSetup('', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Covers documents TC_ID= 122631,122632,122634,122635.
        // Check that Detailed Ledger Entry Unapplied field is set to TRUE, Customer Ledger Entry and G/L entry have correct
        // Remaining Amount and Additional Currency amount as well after Apply and Unapply Ledger Entry.

        // Setup.
        Initialize();

        // Create, Post and Apply General journal Lines.
        PostApplyGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment,
          LibraryRandom.RandInt(500));

        // Exercise: Unapply Customer Ledger Entry.
        UnapplyCustLedgerEntry(GenJournalLine."Account No.", GenJournalLine."Document No.");

        // Verify: Verify Unapply Detailed Ledger Entry, Customer Ledger Entry and G/L Entry for Unapplied is set to TRUE, Remaining
        // Amount and Additional currency amount respectively.
        VerifyUnappliedDtldCustLedgEntry(GenJournalLine."Account No.", GenJournalLine."Document No.");
        VerifyCustLedgerEntryForRemAmt(GenJournalLine."Account No.", GenJournalLine."Document No.");
        VerifyAddCurrencyAmount(GenJournalLine."Document No.");

        // Cleanup: Delete Additional Currency and Unrealized VAT set to False from General Ledger Setup and Unrealized VAT type from
        // VAT Posting Setup.
        ModifyVATPostingSetup(UnrealizedVATType::" ");
        ModifyGeneralLedegerSetup('', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Covers documents TC_ID= 122631,122632,122634,122635.
        // Check that Detailed Ledger Entry Unapplied field is set to TRUE, Customer Ledger Entry and G/L entry have correct
        // Remaining Amount and Additional Currency amount as well after Apply and Unapply Ledger Entry.

        // Setup.
        Initialize();

        // Create, Post and Apply General journal Lines.
        PostApplyGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund,
          -LibraryRandom.RandInt(500));

        // Exercise: Unapply Customer Ledger Entry.
        UnapplyCustLedgerEntry(GenJournalLine."Account No.", GenJournalLine."Document No.");

        // Verify: Verify Unapply Detailed Ledger Entry, Customer Ledger Entry and G/L Entry for Unapplied is set to TRUE, Remaining
        // Amount and Additional currency amount respectively.
        VerifyUnappliedDtldCustLedgEntry(GenJournalLine."Account No.", GenJournalLine."Document No.");
        VerifyCustLedgerEntryForRemAmt(GenJournalLine."Account No.", GenJournalLine."Document No.");
        VerifyAddCurrencyAmount(GenJournalLine."Document No.");

        // Cleanup: Delete Additional Currency and Unrealized VAT set to False from General Ledger Setup and Unrealized VAT type from
        // VAT Posting Setup.
        ModifyVATPostingSetup(UnrealizedVATType::" ");
        ModifyGeneralLedegerSetup('', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyCustomerRefundPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Apply] [Unapply] [Customer]
        // [SCENARIO 382503] Unapply Customer Refund and Payment when application is done from posted entries
        Initialize();

        // [GIVEN] Customer Refund and Payment are posted then applied
        PostGenJournalLines(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Refund,
          GenJournalLine."Account Type"::Customer, CreateCustomer(), -LibraryRandom.RandInt(500), 1);
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.", GenJournalLine."Document Type"::Refund, GenJournalLine.Amount);

        // [WHEN] Unapply Payment and Refund
        UnapplyCustLedgerEntry(GenJournalLine."Account No.", GenJournalLine."Document No.");

        // [THEN] Customer Ledger Entries are unapplied
        VerifyUnappliedDtldCustLedgEntry(GenJournalLine."Account No.", GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyCustomerRefundPaymentWhenAppliedOnPosting()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Apply] [Unapply] [Customer]
        // [SCENARIO 382503] Unapply Customer Refund and Payment when application is done with payment posting
        Initialize();

        // [GIVEN] Customer Refund is posted
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateGenJournalLineWithBalanceAcc(
          GenJournalLine, GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Customer, CustomerNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Payment is posted and applied to Refund with Applied-to Doc. No.
        PostApplyPaymentToInvoice(CustLedgerEntry, CustomerNo, GenJournalLine."Document No.", GenJournalLine."Document Type"::Refund);

        // [WHEN] Unapply Payment and Refund
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);

        // [THEN] Customer Ledger Entries are unapplied
        VerifyUnappliedDtldCustLedgEntry(CustomerNo, CustLedgerEntry."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyVendorRefundPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Apply] [Unapply] [Vendor]
        // [SCENARIO 382503] Unapply Vendor Refund and Payment when application is done from posted entries
        Initialize();

        // [GIVEN] Vendor Refund and Payment are posted then applied
        PostGenJournalLines(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Refund,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandInt(500), 1);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Refund, GenJournalLine."Document No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Refund);
        VendorLedgerEntry.FindFirst();
        LibraryERM.ApplyVendorLedgerEntries(
          GenJournalLine."Document Type"::Payment, VendorLedgerEntry."Document Type"::Refund,
          GenJournalLine."Document No.", VendorLedgerEntry."Document No.");

        // [WHEN] Unapply Payment and Refund
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);

        // [THEN] Vendor Ledger Entries are unapplied
        VerifyUnappliedDtldVendLedgEntry(GenJournalLine."Account No.", GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyVendorRefundPaymentWhenAppliedOnPosting()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Apply] [Unapply] [Vendor]
        // [SCENARIO 382503] Unapply Vendor Refund and Payment when application is done with payment posting
        Initialize();

        // [GIVEN] Vendor Refund is posted
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Vendor, VendorNo,
          -LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Payment is posted and applied to Refund with Applied-to Doc. No.
        CreateApplyGenJnlLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Document Type"::Refund, GenJournalLine."Document No.");
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");

        // [WHEN] Unapply Payment and Refund
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);

        // [THEN] Vendor Ledger Entries are unapplied
        VerifyUnappliedDtldVendLedgEntry(GenJournalLine."Account No.", GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlement()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test functionality of Calc. and Post VAT Settlement report.

        // Setup: Create VAT Posting Setup. Create and post General Journal Line.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine);

        // Exercise: Run Calc. and Post VAT Settlement.
        RunCalcAndPostVATSettlement(GenJournalLine);

        // Verify: Verify VAT Settlement Amount.
        VerifyVATSettlementAmount(GenJournalLine."Document No.", -GenJournalLine."VAT Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckEntryInGLEntryVATEntryLink()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLAccount: Record "G/L Account";
        CustomerNo: Code[20];
        OldAdjustForPaymentDiscount: Boolean;
    begin
        // Check that entry is created in GL Entry VAT Entry link when customer payment is upapplied.

        // Setup: Create & Post Sales Journal for invoice and payment.
        Initialize();
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        PrepareSetupWithAdjForPmtDiscount(CustomerNo, OldAdjustForPaymentDiscount, GLAccount);

        CreateGenJournalLineWithBalanceAcc(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PostApplyPaymentToInvoice(CustLedgerEntry, CustomerNo, GenJournalLine."Document No.", GenJournalLine."Document Type"::Invoice);

        // Exercise: Unapply Payment Entry.
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);

        // Verify: Verify Entry created in G/L Entry - VAT Entry link.
        VerifyGLEntryVATEntryLink(CustLedgerEntry);
        VerifyGLEntryDiscountAccPostingGroups(CustLedgerEntry."Document No.", GLAccount);

        // TearDown.
        UpdateVATPostingSetup(GLAccount, OldAdjustForPaymentDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleCorrVATEntryWhenUnapplyPmtWithUnrealVATAndAdjForPmtDisc()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLAccount: Record "G/L Account";
        CustomerNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
        OldAdjustForPaymentDiscount: Boolean;
        InvUnrealVATEntryNo: Integer;
    begin
        // [FEATURE] [Unrealized VAT] [Adjust For Payment Discount]
        // [SCENARIO 371480] Single corrective VAT Entry for Invoice should be created when unapply payment with Unrealized VAT and Adjust For Payment Discount

        Initialize();
        // [GIVEN] Invoice with Unrealized VAT ("VAT Base" = "X", "VAT Amount" = "Y") and Adjust For Payment Discount
        LibraryERM.SetUnrealizedVAT(true);
        GLAccount.Get(CreateGLAccountWithUnrealizedVAT());
        PrepareSetupWithAdjForPmtDiscount(
          CustomerNo, OldAdjustForPaymentDiscount, GLAccount);
        CreateGenJournalLineWithBalanceAcc(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        InvUnrealVATEntryNo := FindVATEntry(GenJournalLine."Document Type", GenJournalLine."Document No.");
        VATBase := GenJournalLine."Bal. VAT Base Amount";
        VATAmount := GenJournalLine."Bal. VAT Amount";
        // [GIVEN] Payment applied to Invoice
        PostApplyPaymentToInvoice(CustLedgerEntry, CustomerNo, GenJournalLine."Document No.", GenJournalLine."Document Type"::Invoice);

        // [WHEN] Unapply Payment
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);

        // [THEN] Single corrective VAT Entry created with "Base" = -"X", "Amount" = "-Y"
        VerifySingleCorrectiveVATEntry(
          CustLedgerEntry."Document Type", CustLedgerEntry."Document No.", InvUnrealVATEntryNo,
          -VATBase, -VATAmount);

        // TearDown.
        UpdateVATPostingSetup(GLAccount, OldAdjustForPaymentDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPostVATSettlementForSalesTax()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATEntry: Record "VAT Entry";
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [SCENARIO 276028] Calc. and Post VAT Settlement for "Sales Tax" VAT Entry
        Initialize();

        // [GIVEN] Posted sales invoice with sales tax setup
        CreateSalesTax(TaxAreaCode, TaxGroupCode);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Tax Area Code", TaxAreaCode);
        SalesHeader.Validate("Tax Liable", true);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run Calc. and Post VAT Settlement report
        CalcAndPostVATSettlement.InitializeRequest(
          WorkDate(), WorkDate(), WorkDate(), LibraryUtility.GenerateGUID(), LibraryERM.CreateGLAccountNo(), false, true);
        CalcAndPostVATSettlement.UseRequestPage(false);
        CalcAndPostVATSettlement.SaveAsXml('');

        // [THEN] VAT Entry for the invoice is closed
        // [THEN] Closing entry created with type 'Settlement'
        VATEntry.SetRange("Bill-to/Pay-to No.", SalesHeader."Sell-to Customer No.");
        VATEntry.FindFirst();
        VATEntry.Get(VATEntry."Closed by Entry No.");
        VATEntry.TestField(Type, VATEntry.Type::Settlement);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementReqPageHandler')]
    [Scope('OnPrem')]
    procedure SalesTaxCalcAndPostVATSettlementAllJurisdictions()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxDetail: Record "Tax Detail";
        VATEntry: Record "VAT Entry";
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
        TaxJurisdictionCode: array[2] of Code[10];
    begin
        // [FEATURE] [Report] [VAT Settlement]
        // [SCENARIO 328943] Report "Calculate and Post VAT Settlement" for Sales Tax includes all Tax Jurisdictions
        Initialize();

        // [GIVEN] VAT Posting Setup "X","Y" for Sales Tax calculation type
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Modify(true);

        // [GIVEN] Vat Entry for Tax Jurisdiction "TJ01", VAT Posting Setup "X","Y" on Posting Date "21-01-2019"
        CreateSalesTaxDetail(TaxDetail);
        TaxJurisdictionCode[1] := TaxDetail."Tax Jurisdiction Code";
        MockVATEntryForVATPostingSetup(VATEntry, TaxDetail, VATPostingSetup, 0, true, CalcDate('<+1D>', WorkDate()));

        // [GIVEN] Vat Entries for Tax Jurisdiction "TJ02", VAT Posting Setup "X","Y" on Posting Dates "20-01-2019" and "21-01-2019"
        CreateSalesTaxDetail(TaxDetail);
        TaxJurisdictionCode[2] := TaxDetail."Tax Jurisdiction Code";
        MockVATEntryForVATPostingSetup(VATEntry, TaxDetail, VATPostingSetup, 0, true, WorkDate());
        MockVATEntryForVATPostingSetup(VATEntry, TaxDetail, VATPostingSetup, 0, true, CalcDate('<+1D>', WorkDate()));

        // [WHEN] Run Calculate And Post VAT Settlement report for VAT Posting Setup "X","Y" for dates starting with "20-01-2019" until "27-01-2019"
        CalcAndPostVATSettlement.SetTableView(VATPostingSetup);
        CalcAndPostVATSettlement.InitializeRequest(
          WorkDate(), CalcDate('<+7D>', WorkDate()), WorkDate(),
          LibraryUtility.GenerateGUID(), LibraryERM.CreateGLAccountNo(), false, false);
        CalcAndPostVATSettlement.SetInitialized(false);
        Commit();
        CalcAndPostVATSettlement.Run();

        // [THEN] Tax Jurisdictions "TJ01" and "TJ02" are included in the report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATEntryGetFiltTaxJurisCd', TaxJurisdictionCode[1]);
        LibraryReportDataset.AssertElementTagWithValueExists('VATEntryGetFiltTaxJurisCd', TaxJurisdictionCode[2]);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM VAT Settlement with Apply");
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM VAT Settlement with Apply");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM VAT Settlement with Apply");
    end;

    local procedure PrepareSetupWithAdjForPmtDiscount(var CustomerNo: Code[20]; var OldAdjustForPaymentDiscount: Boolean; GLAccount: Record "G/L Account")
    begin
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        UpdateGeneralPostingSetup(GLAccount);
        OldAdjustForPaymentDiscount := UpdateVATPostingSetup(GLAccount, true);
        CustomerNo := CreateCustomerWithPaymentTerms();
        UpdateCustVATBusPostingGroup(CustomerNo, GLAccount."VAT Bus. Posting Group");
    end;

    local procedure PostApplyGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        NoOfLines: Integer;
    begin
        // Setup: Create Customer, General Journal Line for 1 Invoice, Credit Memo and more than 1 for Payment, Refund and
        // Random Amount for General Journal Line.
        ModifyGeneralLedegerSetup(CreateCurrency(), true);
        ModifyVATPostingSetup(UnrealizedVATType::First);
        NoOfLines := 2 * LibraryRandom.RandInt(2);

        PostGenJournalLines(
          GenJournalLine, DocumentType, DocumentType2, GenJournalLine."Account Type"::Customer, CreateCustomer(), Amount, NoOfLines);
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.", DocumentType2, -Amount / NoOfLines);
    end;

    local procedure PostGenJournalLines(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; NoOfLines: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch, 1, AccountType, AccountNo, DocumentType, Amount);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, NoOfLines, AccountType, AccountNo, DocumentType2, -Amount / NoOfLines);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; AmountToApply: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
        CustLedgerEntry2.SetRange("Document No.", DocumentNo);
        CustLedgerEntry2.SetRange("Customer No.", CustLedgerEntry."Customer No.");
        CustLedgerEntry2.SetRange(Open, true);
        CustLedgerEntry2.FindSet();
        repeat
            CustLedgerEntry2.CalcFields("Remaining Amount");
            CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
            CustLedgerEntry2.Modify(true);
        until CustLedgerEntry2.Next() = 0;

        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure CreateGLAccountWithUnrealizedVAT(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage);
        exit(
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
    end;

    local procedure CreateGenJournalLineWithBalanceAcc(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; Sign: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Sign * LibraryRandom.RandDecInRange(100, 200, 2));
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateCustomerWithPaymentTerms(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", CreatePaymentTerms());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        // Take Random Values for Payment Terms.
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(10));
        SelectGeneralJournalBatch(GenJournalBatch);

        // Use Random value for Amount because value is not important.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type", GenJournalLine."Account Type",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GenJournalLine."Gen. Posting Type"::Sale),
          LibraryRandom.RandDec(1000, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateApplyGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20])
    begin
        CreateGenJournalLineWithBalanceAcc(
          GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, AccountNo,
          GenJournalLine."Bal. Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo(), 1);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        VatPostingSetup: Record "VAT Posting Setup";
    begin
        VatPostingSetup.SetFilter("VAT %", '>0');
        VatPostingSetup.FindLast();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VatPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);

        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        Commit();
        exit(Currency.Code);
    end;

    local procedure CreateGeneralJournalLines(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; NoofLines: Integer; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        Counter: Integer;
    begin
        for Counter := 1 to NoofLines do
            LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
              AccountType, AccountNo, Amount);
    end;

    local procedure CreateSalesTax(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20])
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxGroup: Record "Tax Group";
        TaxDetail: Record "Tax Detail";
    begin
        CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxJurisdiction.Code);
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(
          TaxDetail, TaxJurisdiction.Code, TaxGroup.Code, TaxDetail."Tax Type"::"Sales Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", LibraryRandom.RandInt(10));
        TaxDetail.Modify(true);
        TaxAreaCode := TaxArea.Code;
        TaxGroupCode := TaxGroup.Code;
    end;

    local procedure CreateTaxJurisdiction(var TaxJurisdiction: Record "Tax Jurisdiction")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
        GLAccount.Modify();
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccount."No.");
        TaxJurisdiction.Validate("Tax Account (Purchases)", GLAccount."No.");
        TaxJurisdiction.Modify(true);
    end;

    local procedure CreateSalesTaxDetail(var TaxDetail: Record "Tax Detail")
    var
        TaxGroup: Record "Tax Group";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroup.Code, TaxDetail."Tax Type"::"Sales Tax", WorkDate());
    end;

    local procedure MockVATEntryForVATPostingSetup(var VATEntry: Record "VAT Entry"; TaxDetail: Record "Tax Detail"; VATPostingSetup: Record "VAT Posting Setup"; TaxAmount: Decimal; TaxLiable: Boolean; PostingDate: Date)
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry."Posting Date" := PostingDate;
        VATEntry."VAT Reporting Date" := PostingDate;
        VATEntry."Tax Type" := VATEntry."Tax Type"::"Sales Tax";
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Tax Group Code" := TaxDetail."Tax Group Code";
        VATEntry."Tax Jurisdiction Code" := TaxDetail."Tax Jurisdiction Code";
        VATEntry."Tax Liable" := TaxLiable;
        VATEntry.Base := LibraryRandom.RandDecInRange(100, 200, 2);
        VATEntry.Amount := TaxAmount;
        VATEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATEntry.Insert();
    end;

    local procedure FindInvoiceAmount(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        exit(CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible");
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
    end;

    local procedure FindVATEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocType);
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.FindLast();
        exit(VATEntry."Entry No.");
    end;

    local procedure ModifyGeneralLedegerSetup(CurrencyCode: Code[10]; UnrealizedVAT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure ModifyVATPostingSetup(UnrealizedVATType: Option)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.SetFilter("VAT %", '>0');
        VATPostingSetup.FindLast();
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedVATType);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.FindDirectPostingGLAccount(GLAccount));
        VATPostingSetup.Modify(true);
    end;

    local procedure RunCalcAndPostVATSettlement(GenJournalLine: Record "Gen. Journal Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
        FilePath: Text[1024];
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", GenJournalLine."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("VAT Prod. Posting Group", GenJournalLine."VAT Prod. Posting Group");
        Clear(CalcAndPostVATSettlement);
        CalcAndPostVATSettlement.SetTableView(VATPostingSetup);
        CalcAndPostVATSettlement.InitializeRequest(
          WorkDate(), WorkDate(), WorkDate(), GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", false, true);
        CalcAndPostVATSettlement.UseRequestPage(false);
        FilePath := TemporaryPath + Format(VATPostingSetup.TableName) + '.xlsx';
        CalcAndPostVATSettlement.SaveAsExcel(FilePath)
    end;

    local procedure PostApplyPaymentToInvoice(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocNo: Code[20]; DocType: Enum "Gen. Journal Document Type")
    var
        BankAccount: Record "Bank Account";
        PaymentGenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.FindBankAccount(BankAccount);
        CreateGenJournalLineWithBalanceAcc(
          PaymentGenJournalLine, PaymentGenJournalLine."Document Type"::Payment, PaymentGenJournalLine."Account Type"::Customer, CustomerNo,
          PaymentGenJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.", -1);
        SetAppliesToDoc(PaymentGenJournalLine, DocNo, DocType);
        LibraryERM.PostGeneralJnlLine(PaymentGenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, PaymentGenJournalLine."Document Type", PaymentGenJournalLine."Document No.");
    end;

    local procedure SetAppliesToDoc(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        GenJournalLine.Validate("Applies-to Doc. Type", DocumentType);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Validate(Amount, -FindInvoiceAmount(DocumentNo, DocumentType));
        GenJournalLine.Modify(true);
    end;

    local procedure SelectGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectLastGenJnBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure UnapplyCustLedgerEntry(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindLast();
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure UpdateGeneralPostingSetup(GLAccount: Record "G/L Account")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", GLAccount."No.");
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateVATPostingSetup(GLAccount: Record "G/L Account"; AdjustForPaymentDiscount: Boolean) OldAdjustForPaymentDiscount: Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        OldAdjustForPaymentDiscount := VATPostingSetup."Adjust for Payment Discount";
        VATPostingSetup.Validate("Adjust for Payment Discount", AdjustForPaymentDiscount);
        VATPostingSetup.Modify(true);
        exit(OldAdjustForPaymentDiscount);
    end;

    local procedure UpdateCustVATBusPostingGroup(CustNo: Code[20]; VATBusPostGroupCode: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustNo);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostGroupCode);
        Customer.Modify(true);
    end;

    local procedure VerifyVATSettlementAmount(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Gen. Posting Type", GLEntry."Gen. Posting Type"::Settlement);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyUnappliedDtldCustLedgEntry(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.FindSet();
        repeat
            Assert.IsTrue(DetailedCustLedgEntry.Unapplied, StrSubstNo(UnappliedError, DetailedCustLedgEntry.TableCaption(),
                DetailedCustLedgEntry.Unapplied));
        until DetailedCustLedgEntry.Next() = 0;
    end;

    local procedure VerifyUnappliedDtldVendLedgEntry(VendorNo: Code[20]; DocumentNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DetailedVendorLedgEntry.FindSet();
        repeat
            Assert.IsTrue(DetailedVendorLedgEntry.Unapplied, StrSubstNo(UnappliedError, DetailedVendorLedgEntry.TableCaption(),
                DetailedVendorLedgEntry.Unapplied));
        until DetailedVendorLedgEntry.Next() = 0;
    end;

    local procedure VerifyCustLedgerEntryForRemAmt(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindSet();
        repeat
            CustLedgerEntry.CalcFields("Remaining Amount", Amount);
            CustLedgerEntry.TestField("Remaining Amount", CustLedgerEntry.Amount);
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure VerifyAddCurrencyAmount(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        AddCurrAmt: Decimal;
    begin
        GeneralLedgerSetup.Get();
        Currency.Get(GeneralLedgerSetup."Additional Reporting Currency");
        Currency.InitRoundingPrecision();
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst();
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
        repeat
            AddCurrAmt :=
              (GLEntry.Amount * CurrencyExchangeRate."Exchange Rate Amount") / CurrencyExchangeRate."Relational Adjmt Exch Rate Amt";
            Assert.AreNearlyEqual(AddCurrAmt, GLEntry."Additional-Currency Amount", Currency."Amount Rounding Precision",
              StrSubstNo(AdditionalCurrencyError, AddCurrAmt));
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyGLEntryVATEntryLink(CustLedgEntry: Record "Cust. Ledger Entry")
    var
        GLEntry: Record "G/L Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        GLRegister: Record "G/L Register";
    begin
        FindGLEntry(GLEntry, CustLedgEntry."Document Type"::" ", CustLedgEntry."Document No.");
        GLRegister.SetRange("From Entry No.", GLEntry."Entry No.");
        GLRegister.FindFirst();
        GLEntryVATEntryLink.Get(GLEntry."Entry No.", GLRegister."To VAT Entry No.");
    end;

    local procedure VerifyGLEntryDiscountAccPostingGroups(DocumentNo: Code[20]; GLAccount: Record "G/L Account")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::" ");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type");
        GLEntry.SetRange("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        GLEntry.SetRange("Gen. Prod. Posting Group", GLAccount."Gen. Prod. Posting Group");
        GLEntry.SetRange("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        GLEntry.SetRange("VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
        Assert.IsFalse(GLEntry.IsEmpty, PostingGroupsErr);
    end;

    local procedure VerifySingleCorrectiveVATEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; UnrealVATEntryNo: Integer; VATBase: Decimal; VATAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocType);
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.SetRange("Unrealized VAT Entry No.", UnrealVATEntryNo);
        VATEntry.FindLast();
        Assert.AreEqual(VATBase, VATEntry.Base, VATEntry.FieldCaption(Base));
        Assert.AreEqual(VATAmount, VATEntry.Amount, VATEntry.FieldCaption(Amount));
        VATEntry.SetRange("Transaction No.", VATEntry."Transaction No.");
        Assert.AreEqual(1, VATEntry.Count, IncorrectVATEntryCountErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementReqPageHandler(var CalcandPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    begin
        CalcandPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

