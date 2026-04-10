codeunit 147140 "ERM Sales VAT Ledger Export"
{
    // // [FEATURE] [VAT Ledger] [Sales]
    // // Empty VersionList not to run tests in Snap

    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "VAT Ledger Line" = imd,
                  tabledata "VAT Entry" = imd;

    var
        LibraryVATLedger: Codeunit "Library - VAT Ledger";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRUReports: Codeunit "Library RU Reports";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic18()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // [SCENARIO ID.1] Sales Book Basic - VAT 18%
        Initialize();

        // [GIVEN] Create and post sales invoice with new customer VAT 18%
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', VATLedgerMgt.GetVATPctRate2018(), false);

        // [WHEN] Run report Sales VAT Ledger Export
        RunVATLedgerExportReport(SalesHeader."Sell-to Customer No.", false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyVATLedgExportBasic18(InvNo, false, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic20()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // [SCENARIO 303035] Sales Book Basic - VAT 20%
        Initialize();

        // [GIVEN] Create and post sales invoice with new customer VAT 20%
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', VATLedgerMgt.GetVATPctRate2019(), false);

        // [WHEN] Run report Sales VAT Ledger Export
        RunVATLedgerExportReport(SalesHeader."Sell-to Customer No.", false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount exported to the proper Excel cells
        VerifyVATLedgExportBasic20(InvNo, false, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic10()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
        VATLedgerCode: Code[20];
    begin
        // [SCENARIO ID.3] Sales Book Basic - VAT 10%
        Initialize();

        // [GIVEN] Create and post sales invoice with new customer VAT 10% ("Package No." = "A","B" "Tariff No." = "Y")
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', 10, false);

        // [WHEN] Run report Sales VAT Ledger Export
        VATLedgerCode := RunVATLedgerExportReport(SalesHeader."Sell-to Customer No.", false);

        // [THEN] Document Date, Amount Including VAT, Full VAT Amount exported to the proper Excel cells
        // [THEN] Column 3a = "A;B" ("Package No.", TFS 231729, 251086)
        // [THEN] Column 3b = "Y" ("Tariff No.", TFS 231729)
        VerifyVATLedgExportBasic10(InvNo, VATLedgerCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic18_10_0()
    var
        CustomerNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO ID.4] Sales Book 18+10+0%
        Initialize();

        // [GIVEN] Create and post sales invoice with 3 lines VAT 18%, 10% and 0%
        InvNo := CreateAndPostSalesInvoiceMultiLines(CustomerNo, '', VATLedgerMgt.GetVATPctRate2018());

        // [WHEN] Run report Sales VAT Ledger Export
        RunVATLedgerExportReport(CustomerNo, false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyVATLedgExportBasic18_10_0(InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic20_10_0()
    var
        CustomerNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO 303035] Sales Book 20+10+0%
        Initialize();

        // [GIVEN] Create and post sales invoice with 3 lines VAT 20%, 10% and 0%
        InvNo := CreateAndPostSalesInvoiceMultiLines(CustomerNo, '', VATLedgerMgt.GetVATPctRate2019());

        // [WHEN] Run report Sales VAT Ledger Export
        RunVATLedgerExportReport(CustomerNo, false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount exported to the proper Excel cells
        VerifyVATLedgExportBasic20_10_0(InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic18FCY()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // [SCENARIO 362667] Sales Book FCY (VAT 18%)
        Initialize();

        // [GIVEN] Create and post sales invoice for new customer with currency
        InvNo := CreateAndPostSalesInvoice(SalesHeader, CreateCurrency(false), VATLedgerMgt.GetVATPctRate2018(), false);

        // [WHEN] Run report Sales VAT Ledger Export
        RunVATLedgerExportReport(SalesHeader."Sell-to Customer No.", false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyVATLedgExportBasic18FCY(InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic20FCY()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // [SCENARIO 303035] Sales Book FCY (VAT 20%)
        Initialize();

        // [GIVEN] Create and post sales invoice for new customer with currency
        InvNo := CreateAndPostSalesInvoice(SalesHeader, CreateCurrency(false), VATLedgerMgt.GetVATPctRate2019(), false);

        // [WHEN] Run report Sales VAT Ledger Export
        RunVATLedgerExportReport(SalesHeader."Sell-to Customer No.", false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount exported to the proper Excel cells
        VerifyVATLedgExportBasic20FCY(InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic18FCYConventional()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // [SCENARIO 362467] Sales Book Conventional Currency (VAT 18%)
        Initialize();

        // [GIVEN] Create and post sales invoice "X" for new customer with conventional currency
        // [GIVEN] where "Amount Including VAT (LCY)" = "A", "Amount (LCY)" = "B".
        InvNo := CreateAndPostSalesInvoice(SalesHeader, CreateCurrency(true), VATLedgerMgt.GetVATPctRate2018(), false);

        // [WHEN] Run report Sales VAT Ledger Export
        RunVATLedgerExportReport(SalesHeader."Sell-to Customer No.", false);

        // [THEN] Column 3 value equals "X"."No."; "X"."Document Date"
        // [THEN] Column 12 value is empty
        // [THEN] Column 13a value is empty (TFS 378923)
        // [THEN] Column 14a value equals "X"."B"
        // [THEN] Column 17a value equals "X"."A" - "X"."B"
        VerifyVATLedgExportConventionalRelational18(InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic20FCYConventional()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // [SCENARIO 303035] Sales Book Conventional Currency (VAT 20%)
        Initialize();

        // [GIVEN] Create and post sales invoice "X" for new customer with conventional currency
        // [GIVEN] where "Amount Including VAT (LCY)" = "A", "Amount (LCY)" = "B".
        InvNo := CreateAndPostSalesInvoice(SalesHeader, CreateCurrency(true), VATLedgerMgt.GetVATPctRate2019(), false);

        // [WHEN] Run report Sales VAT Ledger Export
        RunVATLedgerExportReport(SalesHeader."Sell-to Customer No.", false);

        // [THEN] Column 3 value equals "X"."No."; "X"."Document Date"
        // [THEN] Column 12 value is empty
        // [THEN] Column 13a value is empty (TFS 378923)
        // [THEN] Column 14 value equals "X"."B"
        // [THEN] Column 17 value equals "X"."A" - "X"."B"
        VerifyVATLedgExportConventionalRelational20(InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic18FCYRelationalCurr()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // [SCENARIO 364295] Sales VAT Ledger Export Report for Sales Invoice with FCY having Relational Currency Code (VAT 18%)
        Initialize();

        // [GIVEN] Posted Sales Invoice "X" with FCY having Relational Currency Code
        // [GIVEN] where "Amount Including VAT (LCY)" = 118, "Amount (LCY)" = 100
        InvNo := CreateAndPostSalesInvoice(SalesHeader, CreateCurrWithRelationalCurrCode(), VATLedgerMgt.GetVATPctRate2018(), false);

        // [WHEN] Run report Sales VAT Ledger Export
        RunVATLedgerExportReport(SalesHeader."Sell-to Customer No.", false);

        // [THEN] Column 3 value equals "X"."No."; "X"."Document Date"
        // [THEN] Column 12 value is empty
        // [THEN] Column 13a value is empty (TFS 378923)
        // [THEN] Column 14a value equals 100
        // [THEN] Column 17a value equals 118 - 100 = 18
        VerifyVATLedgExportConventionalRelational18(InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic20FCYRelationalCurr()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // [SCENARIO 303035] Sales VAT Ledger Export Report for Sales Invoice with FCY having Relational Currency Code (VAT 20%)
        Initialize();

        // [GIVEN] Posted Sales Invoice "X" with FCY having Relational Currency Code
        // [GIVEN] where "Amount Including VAT (LCY)" = 120, "Amount (LCY)" = 100
        InvNo := CreateAndPostSalesInvoice(SalesHeader, CreateCurrWithRelationalCurrCode(), VATLedgerMgt.GetVATPctRate2019(), false);

        // [WHEN] Run report Sales VAT Ledger Export
        RunVATLedgerExportReport(SalesHeader."Sell-to Customer No.", false);

        // [THEN] Column 3 value equals "X"."No."; "X"."Document Date"
        // [THEN] Column 12 value is empty
        // [THEN] Column 13a value is empty (TFS 378923)
        // [THEN] Column 14 value equals 100
        // [THEN] Column 17 value equals 120 - 100 = 20
        VerifyVATLedgExportConventionalRelational20(InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportAdvance()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        DocNo: Code[20];
        VATRate: Decimal;
    begin
        // [SCENARIO ID.8] Advance payment
        Initialize();

        // [GIVEN] Create new customer
        VATRate := VATLedgerMgt.GetVATPctRate2019();
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        CustomerNo := CreateCustomer(VATPostingSetup);
        LibraryRUReports.UpdateCustomerPrepmtAccountVATRate(CustomerNo, VATRate);

        // [GIVEN] Create and post sales invoice with VAT 18%
        DocNo := CreateAndReleaseSalesInvoice(CustomerNo, VATPostingSetup, '');
        CreatePrepaymentJournalLine(
          GenJnlLine, GenJnlLine."Account Type"::Customer, CustomerNo, DocNo, -LibraryRandom.RandInt(100));
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [WHEN] Run report Sales VAT Ledger Export
        RunVATLedgerExportReport(CustomerNo, false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyVATLedgExportBasicAdvance(GenJnlLine, VATRate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportAdvancePostInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        DocNo: Code[20];
        CustomerNo: Code[20];
        VATRate: Decimal;
    begin
        // [SCENARIO 379308] Post Sales Invoice after Advance payment
        Initialize();

        // [GIVEN] Released Sales Invoice with VAT Base = "A"
        VATRate := VATLedgerMgt.GetVATPctRate2019();
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        CustomerNo := CreateCustomer(VATPostingSetup);
        LibraryRUReports.UpdateCustomerPrepmtAccountVATRate(CustomerNo, VATRate);

        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateAndReleaseSalesInvoice(CustomerNo, VATPostingSetup, ''));
        // [GIVEN] Posted advance payment
        CreatePrepaymentJournalLine(
          GenJnlLine, GenJnlLine."Account Type"::Customer, CustomerNo, SalesHeader."No.", -LibraryRandom.RandInt(100));
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        // [GIVEN] Post Sales Invoice
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run report Sales VAT Ledger Export
        RunVATLedgerExportReport(CustomerNo, false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount exported to the  proper Excel cells
        // [THEN] Column 14 = '-' for advance line (TFS 379308)
        // [THEN] Column 14 = 'A' for invoice line (TFS 379308)
        VerifyVATLedgExportBasicAdvance(GenJnlLine, VATRate);
        VerifyVATLedgExportBasic20(DocNo, false, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportAddSheet()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
        VATRate: Decimal;
    begin
        // [SCENARIO ID.16] Sales Book add. Sheet - VAT 18%
        Initialize();

        // [GIVEN] Create and post sales invoice with new customer VAT 18%
        VATRate := VATLedgerMgt.GetVATPctRate2019();
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', VATRate, true);

        // [WHEN] Run report Sales VAT Ledger Export
        RunVATLedgerExportReport(SalesHeader."Sell-to Customer No.", true);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyVATLedgExportBasic20(InvNo, true, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportCorrection()
    var
        CorSalesHeader: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
        CorInvNo: Code[20];
    begin
        // [SCENARIO ID.17] Sales Book with correction
        Initialize();

        // [GIVEN] Create and post corrective sales invoice
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', VATLedgerMgt.GetVATPctRate2019(), false);
        CorInvNo := CreatePostCorrSalesInvoice(CorSalesHeader, SalesHeader, InvNo);

        // [WHEN] Run report Sales VAT Ledger Export
        RunVATLedgerExportReport(CorSalesHeader."Sell-to Customer No.", false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyVATLedgExportCorrection(CorInvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportRevision()
    var
        RevSalesHeader: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
        RevInvNo: Code[20];
    begin
        // [SCENARIO ID.18] Sales Book with revision
        Initialize();

        // [GIVEN] Create and post revision sales invoice
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', VATLedgerMgt.GetVATPctRate2019(), false);
        RevInvNo := CreatePostRevisionSalesInvoice(RevSalesHeader, SalesHeader, InvNo);

        // [WHEN] Run report Sales VAT Ledger Export
        RunVATLedgerExportReport(SalesHeader."Sell-to Customer No.", false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyVATLedgExportRevision(RevInvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportRevCorr()
    var
        SalesHeader: Record "Sales Header";
        CorSalesHeader: Record "Sales Header";
        RevSalesHeader: Record "Sales Header";
        InvNo: Code[20];
        CorInvNo: Code[20];
        RevInvNo: Code[20];
    begin
        // [SCENARIO ID.19] Sales Book with revision for correction
        Initialize();

        // [GIVEN] Create and post revision sales invoice for correction
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', VATLedgerMgt.GetVATPctRate2019(), false);
        CorInvNo := CreatePostCorrSalesInvoice(CorSalesHeader, SalesHeader, InvNo);
        RevInvNo := CreatePostRevisionSalesInvoice(RevSalesHeader, CorSalesHeader, CorInvNo);

        // [WHEN] Run report Sales VAT Ledger Export
        RunVATLedgerExportReport(SalesHeader."Sell-to Customer No.", false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyVATLedgExportRevOfCorr(CorInvNo, RevInvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportVendorPrpmt()
    var
        CompanyInformation: Record "Company Information";
        PurchaseHeader: Record "Purchase Header";
        CompanyType: Option Person,Organization;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 374734] Exported purchase prepayment via VAT Sales Ledger has company's VAT Reg No. and KPP Code
        Initialize();

        // [GIVEN] "Company Information"."VAT Registration No." = "X"
        // [GIVEN] "Company Information"."KPP Code" = "Y"
        LibraryRUReports.UpdateCompanyTypeInfo(CompanyType::Organization);

        // [GIVEN] Purchase Invoice applied to Prepayment
        CreatePurchaseInvoiceVendorVATAgent(PurchaseHeader);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PostAndApplyPurchasePrepayment(PurchaseHeader);

        // [WHEN] Export Sales VAT Ledger to XML
        RunVATLedgerExportReport(PurchaseHeader."Buy-from Vendor No.", false);

        // [THEN] Exported CV "VAT Registration No." = "Company Information"."VAT Registration No." = "X"
        // [THEN] Exported CV "KPP Code" = "Company Information"."KPP Code" = "Y"
        CompanyInformation.Get();
        VerifyVATLedgExportVendorPrpmt(CompanyInformation."VAT Registration No." + ' / ' + CompanyInformation."KPP Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportAddSheetTwoPeriods()
    var
        CustomerNo: Code[20];
        InvNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [Additional sheet] Sales Book add. sheet 2 periods
        Initialize();

        // [GIVEN] Create and post 2 sales invoices with different periods
        SalesVATLedgerAddSheetTwoPeriodsScenario(CustomerNo, InvNo);

        // [WHEN] Run report Sales VAT Ledger Export
        RunVATLedgerExportReport(CustomerNo, true);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount exported to the proper Excel sheets
        VerifyVATLedgExportAddSheetTwoPeriods(InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportVATAgentPaymentAfterManualVATSettlement()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 378466] Payment document no. and date are exported in column 11 in case of VAT Agent payment after manual VAT Settlement
        Initialize();
        DeleteVATEntriesOnDate(WorkDate() - 1, WorkDate() + 1);

        // [GIVEN] VAT Agent vendor with manual VAT Settlement VAT Posting Setup
        CreatePurchaseInvoiceVendorVATAgent(PurchaseHeader);
        LibraryRUReports.GetVATAgentPostingSetup(VATPostingSetup, PurchaseHeader."Buy-from Vendor No.");
        LibraryRUReports.UpdateVATPostingSetupWithManualVATSettlement(VATPostingSetup);
        PurchaseHeader.CalcFields("Amount Including VAT");
        // [GIVEN] Posted purchase invoice
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [GIVEN] Posted payment with "External Document No." = "X", "Posting Date" = "Y"
        PostPurchasePayment(GenJournalLine, PurchaseHeader."Buy-from Vendor No.", InvoiceNo, PurchaseHeader."Amount Including VAT");
        // [GIVEN] Suggest and post VAT Settlement
        LibraryRUReports.SuggestPostManualVATSettlement(PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Export Sales VAT Ledger to XML
        RunVATLedgerExportReport(PurchaseHeader."Buy-from Vendor No.", false);

        // [THEN] Exported column 11 (document no. and date that confirm payment) = "X; Y"
        VerifyVATLedgerExport_DocPdtvOpl(19, GenJournalLine."External Document No.", GenJournalLine."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportVATAgentPrepaymentAfterManualVATSettlement()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Purchase] [Prepayment]
        // [SCENARIO 378466] Prepayment document no. and date are exported in column 11 in case of VAT Agent prepayment after manual VAT Settlement
        Initialize();
        DeleteVATEntriesOnDate(WorkDate() - 1, WorkDate() + 1);

        // [GIVEN] VAT Agent vendor with manual VAT Settlement VAT Posting Setup
        CreatePurchaseInvoiceVendorVATAgent(PurchaseHeader);
        LibraryRUReports.GetVATAgentPostingSetup(VATPostingSetup, PurchaseHeader."Buy-from Vendor No.");
        LibraryRUReports.UpdateVATPostingSetupWithManualVATSettlement(VATPostingSetup);
        // [GIVEN] Released purchase invoice
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        // [GIVEN] Posted prepayment with "External Document No." = "X", "Posting Date" = "Y"
        PostPurchasePrepayment(GenJournalLine, PurchaseHeader);
        // [GIVEN] Suggest and post VAT Settlement
        LibraryRUReports.SuggestPostManualVATSettlement(PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Export Sales VAT Ledger to XML
        RunVATLedgerExportReport(PurchaseHeader."Buy-from Vendor No.", false);

        // [THEN] Exported column 11 (document no. and date that confirm payment) = "X; Y"
        VerifyVATLedgerExport_DocPdtvOpl(19, GenJournalLine."External Document No.", GenJournalLine."Posting Date");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        UpdateStockOutAndCreditWarnings();
        // "Posted VAT Agent No. Series" is blank in standard DB
        // We need keep the same series for the whole codeunit scope to avoid numbering conflict
        UpdatePostedVATAgentNoSeriesInPurchSetup(LibraryERM.CreateNoSeriesCode());
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify();
        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
    end;

    local procedure CreateCustomer(var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    begin
        exit(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; CurrencyCode: Code[10])
    begin
        LibraryRUReports.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, CurrencyCode);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesLine: Record "Sales Line";
    begin
        LibraryRUReports.CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup);
    end;

    local procedure CreatePurchaseInvoiceVendorVATAgent(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorVATAgent());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(5));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateCurrency(IsConventional: Boolean): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());
        Currency.Validate(Conventional, IsConventional);
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure RunVATLedgerExportReport(CustomerNo: Code[20]; AddSheet: Boolean) VATLedgerCode: Code[20]
    var
        FileName: Text[1024];
    begin
        VATLedgerCode :=
          LibrarySales.CreateSalesVATLedger(LibraryRandom.RandDate(-2), LibraryRandom.RandDateFromInRange(WorkDate(), 5, 10), CustomerNo);
        if AddSheet then
            LibrarySales.CreateSalesVATLedgerAddSheet(VATLedgerCode);
        UpdateVATLedgerLineWithRandomCDNoAndTariffNo(VATLedgerCode, CustomerNo);

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        FileName := LibraryReportValidation.GetFileName();
        LibrarySales.ExportSalesVATLedger(VATLedgerCode, AddSheet, FileName);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10]; VATRate: Decimal; AddSheet: Boolean): Code[20]
    begin
        if AddSheet then
            exit(LibraryRUReports.CreatePostSalesInvoiceAddSheet(SalesHeader, CurrencyCode, VATRate));
        exit(LibraryRUReports.CreatePostSalesInvoice(SalesHeader, CurrencyCode, VATRate));
    end;

    local procedure CreateAndPostSalesInvoiceMultiLines(var CustomerNo: Code[20]; CurrencyCode: Code[10]; NormalVATRate: Decimal): Code[20]
    begin
        exit(LibraryRUReports.CreatePostSalesInvoiceMultiLines(CustomerNo, CurrencyCode, NormalVATRate));
    end;

    local procedure CreateAndReleaseSalesInvoice(CustomerNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibraryRUReports.CreateReleaseSalesInvoice(SalesHeader, VATPostingSetup, CustomerNo, CurrencyCode);
        exit(SalesHeader."No.");
    end;

    local procedure CreatePostCorrSalesInvoice(var CorrSalesHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; InvNo: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCorrectiveSalesInvoice(
          CorrSalesHeader, SalesHeader."Bill-to Customer No.", InvNo,
          CorrSalesHeader."Corrective Doc. Type"::Correction, CalcDate('<1D>', SalesHeader."Posting Date"));
        FindSalesLine(SalesLine, CorrSalesHeader);
        UpdateQuantityInSalesLine(SalesLine, LibraryRandom.RandIntInRange(3, 5));
        exit(LibrarySales.PostSalesDocument(CorrSalesHeader, true, true));
    end;

    local procedure CreatePostRevisionSalesInvoice(var CorrSalesHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; InvNo: Code[20]): Code[20]
    begin
        LibrarySales.CreateCorrectiveSalesInvoice(
          CorrSalesHeader, SalesHeader."Bill-to Customer No.", InvNo,
          CorrSalesHeader."Corrective Doc. Type"::Revision, CalcDate('<1D>', SalesHeader."Posting Date"));
        exit(LibrarySales.PostSalesDocument(CorrSalesHeader, true, true));
    end;

    local procedure CreateCurrWithRelationalCurrCode(): Code[10]
    var
        Currency: Record Currency;
        RelationalCurrency: Record Currency;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());
        RelationalCurrency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());
        UpdateCurrExchRateWithRelationalCurrCode(Currency.Code, RelationalCurrency.Code);
        exit(Currency.Code);
    end;

    local procedure GetCurrDescription(CurrencyCode: Code[10]): Text
    var
        Currency: Record Currency;
    begin
        if CurrencyCode <> '' then begin
            Currency.Get(CurrencyCode);
            exit(LowerCase(CopyStr(Currency.Description, 1, 1)) + CopyStr(Currency.Description, 2));
        end;
        exit('');
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
    end;

    local procedure FormatValue(Value: Decimal): Text
    var
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        exit(LocalReportMgt.FormatReportValue(Value, 2));
    end;

    local procedure CreatePrepaymentJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PrepDocNo: Code[20]; LineAmount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, AccountNo, LineAmount);
        GenJournalLine.Validate(Prepayment, true);
        GenJournalLine.Validate("Prepayment Document No.", PrepDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePaymentJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; InitDocNo: Code[20]; LineAmount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, AccountNo, LineAmount);
        GenJournalLine.Validate("Posting Date", WorkDate() - 1);
        GenJournalLine.Validate("Initial Document No.", InitDocNo);
        GenJournalLine.Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
    end;

    local procedure MockTwoVATLedgerLineCDNos(VATLedgerLine: Record "VAT Ledger Line")
    begin
        LibraryVATLedger.MockVATLedgerLineCDNo(VATLedgerLine, LibraryVATLedger.GenerateCDNoValue());
        LibraryVATLedger.MockVATLedgerLineCDNo(VATLedgerLine, LibraryVATLedger.GenerateCDNoValue());
    end;

    local procedure SalesVATLedgerAddSheetTwoPeriodsScenario(var CustomeNo: Code[20]; var InvNo: array[2] of Code[20])
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATRate: Decimal;
    begin
        VATRate := VATLedgerMgt.GetVATPctRate2019();
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        CustomeNo := CreateCustomer(VATPostingSetup);
        CreateSalesHeader(SalesHeader, CustomeNo, '');

        LibraryRUReports.UpdateSalesHeaderWithAddSheetInfo(SalesHeader, '<1M>');
        CreateSalesLine(SalesHeader, VATPostingSetup);
        InvNo[1] := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CreateSalesHeader(SalesHeader, CustomeNo, '');

        LibraryRUReports.UpdateSalesHeaderWithAddSheetInfo(SalesHeader, '<2M>');
        CreateSalesLine(SalesHeader, VATPostingSetup);
        InvNo[2] := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure UpdateQuantityInSalesLine(var SalesLine: Record "Sales Line"; Multiplier: Decimal)
    begin
        SalesLine.Validate("Quantity (After)", Round(SalesLine."Quantity (After)" * Multiplier, 1));
        SalesLine.Modify(true);
    end;

    local procedure UpdateCurrExchRateWithRelationalCurrCode(CurrCode: Code[10]; RelationalCurrCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate.Validate("Relational Currency Code", RelationalCurrCode);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure UpdateStockOutAndCreditWarnings()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"No Warning");
        SalesReceivablesSetup."Stockout Warning" := false;
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdatePostedVATAgentNoSeriesInPurchSetup(SeriesCode: Code[20])
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Posted VAT Agent Invoice Nos." := SeriesCode;
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateVATLedgerLineWithRandomCDNoAndTariffNo(VATLedgerCode: Code[20]; CVNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        LibraryRUReports.FindVATLedgerLine(VATLedgerLine, VATLedgerLine.Type::Sales, VATLedgerCode, CVNo);
        MockTwoVATLedgerLineCDNos(VATLedgerLine);
        VATLedgerLine.Validate("Tariff No.", LibraryVATLedger.MockTariffNo());
        VATLedgerLine.Modify(true);
    end;

    local procedure PostAndApplyPurchasePrepayment(var PurchaseHeader: Record "Purchase Header")
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
    begin
        // create and post prepayment
        PostPurchasePrepayment(GenJournalLine, PurchaseHeader);

        // post invoice
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // post application
        LibraryERM.ApplyVendorLedgerEntry(
          VendorLedgerEntry."Document Type"::Invoice, InvoiceNo,
          VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
    end;

    local procedure PostPurchasePrepayment(var GenJournalLine: Record "Gen. Journal Line"; var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.CalcFields("Amount Including VAT");
        CreatePrepaymentJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
          PurchaseHeader."No.", PurchaseHeader."Amount Including VAT");
        GenJournalLine.Validate("Posting Date", LibraryRandom.RandDate(-1));
        GenJournalLine.Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostPurchasePayment(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; InvoiceNo: Code[20]; Amount: Decimal)
    begin
        CreatePaymentJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, InvoiceNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure GetSalesInvHeader(InvNo: Code[20]; var SalesInvHeader: Record "Sales Invoice Header"; var SalesInvLine: Record "Sales Invoice Line")
    begin
        SalesInvHeader.Get(InvNo);
        SalesInvHeader.CalcFields("Amount Including VAT");
        SalesInvLine.SetRange("Document No.", InvNo);
        SalesInvLine.FindFirst();
    end;

    local procedure DeleteVATEntriesOnDate(StartDate: Date; EndDate: Date)
    var
        VATEntry: Record "VAT Entry";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
    begin
        VATLedgerMgt.SetVATPeriodFilter(VATEntry, StartDate, EndDate);
        VATEntry.DeleteAll();
    end;

    local procedure VerifyRepCommonValues(SalesInvHeader: Record "Sales Invoice Header"; RowNo: Integer; LineNo: Integer)
    var
        Customer: Record Customer;
    begin
        Customer.Get(SalesInvHeader."Sell-to Customer No.");
        VerifyColumn1(RowNo, Format(LineNo));
        VerifyColumn2(RowNo, SalesInvHeader."VAT Entry Type");
        VerifyColumn3(RowNo, SalesInvHeader."No." + '; ' + Format(SalesInvHeader."Document Date"));
        VerifyColumn7(RowNo, Customer.Name);
        VerifyColumn9(RowNo, '');
        VerifyColumn10(RowNo, '');
        VerifyColumn12(RowNo, '');
    end;

    local procedure VerifyVATLedgExportBasic20(InvNo: Code[20]; AddSheet: Boolean; LineNo: Integer)
    var
        RowNo: Integer;
    begin
        if AddSheet then
            RowNo := 15
        else
            RowNo := 19;

        RowNo += LineNo - 1;
        VerifyExcelRowBasic20(InvNo, RowNo, LineNo);
    end;

    local procedure VerifyVATLedgExportBasic18(InvNo: Code[20]; AddSheet: Boolean; LineNo: Integer)
    var
        RowNo: Integer;
    begin
        if AddSheet then
            RowNo := 15
        else
            RowNo := 19;

        RowNo += LineNo - 1;
        VerifyExcelRowBasic18(InvNo, RowNo, LineNo);
    end;

    local procedure VerifyVATLedgExportBasic10(InvNo: Code[20]; VATLedgerCode: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        VATLedgerLine: Record "VAT Ledger Line";
        RowNo: Integer;
    begin
        RowNo := 19;
        GetSalesInvHeader(InvNo, SalesInvHeader, SalesInvLine);
        VerifyRepCommonValues(SalesInvHeader, RowNo, 1);

        LibraryRUReports.FindVATLedgerLine(VATLedgerLine, VATLedgerLine.Type::Sales, VATLedgerCode, SalesInvHeader."Sell-to Customer No.");
        VerifyColumn20(RowNo, VATLedgerLine.GetCDNoListString());
        VerifyColumn3a(RowNo, VATLedgerLine."Tariff No.");

        VerifyColumn13a(RowNo, '');
        VerifyColumn13b(RowNo, FormatValue(SalesInvLine."Amount Including VAT"));
        VerifyColumn14(RowNo, '');
        VerifyColumn14a(RowNo, '');
        VerifyColumn15(RowNo + 1, FormatValue(SalesInvLine.Amount));
        VerifyColumn16(RowNo, '');
        VerifyColumn17(RowNo, '');
        VerifyColumn17a(RowNo, '');
        VerifyColumn18(RowNo, FormatValue(SalesInvLine."Amount Including VAT" - SalesInvLine.Amount));
        VerifyColumn19(RowNo, '');
    end;

    local procedure VerifyVATLedgExportBasic20_10_0(InvNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        RowNo: Integer;
    begin
        RowNo := 19;
        GetSalesInvHeader(InvNo, SalesInvHeader, SalesInvLine);
        VerifyRepCommonValues(SalesInvHeader, RowNo, 1);
        VerifyColumn13b(RowNo, FormatValue(SalesInvHeader."Amount Including VAT"));

        SalesInvLine.SetRange("VAT %", VATLedgerMgt.GetVATPctRate2019());
        SalesInvLine.FindFirst();
        VerifyColumn14(RowNo, FormatValue(SalesInvLine.Amount));
        VerifyColumn17(RowNo, FormatValue(SalesInvLine."Amount Including VAT" - SalesInvLine.Amount));

        SalesInvLine.SetRange("VAT %", 10);
        SalesInvLine.FindFirst();
        VerifyColumn15(RowNo, FormatValue(SalesInvLine.Amount));
        VerifyColumn18(RowNo, FormatValue(SalesInvLine."Amount Including VAT" - SalesInvLine.Amount));
        VerifyColumn15(RowNo + 1, FormatValue(SalesInvLine.Amount));
        VerifyColumn18(RowNo + 1, FormatValue(SalesInvLine."Amount Including VAT" - SalesInvLine.Amount));

        SalesInvLine.SetRange("VAT %", 0);
        SalesInvLine.FindFirst();
        VerifyColumn16(RowNo, FormatValue(SalesInvLine.Amount));
        VerifyColumn16(RowNo + 1, FormatValue(SalesInvLine.Amount));
        VerifyColumn19(RowNo, '');
    end;

    local procedure VerifyVATLedgExportBasic18_10_0(InvNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        RowNo: Integer;
    begin
        RowNo := 19;
        GetSalesInvHeader(InvNo, SalesInvHeader, SalesInvLine);
        VerifyRepCommonValues(SalesInvHeader, RowNo, 1);
        VerifyColumn13b(RowNo, FormatValue(SalesInvHeader."Amount Including VAT"));

        SalesInvLine.SetRange("VAT %", VATLedgerMgt.GetVATPctRate2018());
        SalesInvLine.FindFirst();
        VerifyColumn14a(RowNo, FormatValue(SalesInvLine.Amount));
        VerifyColumn17a(RowNo, FormatValue(SalesInvLine."Amount Including VAT" - SalesInvLine.Amount));

        SalesInvLine.SetRange("VAT %", 10);
        SalesInvLine.FindFirst();
        VerifyColumn15(RowNo, FormatValue(SalesInvLine.Amount));
        VerifyColumn18(RowNo, FormatValue(SalesInvLine."Amount Including VAT" - SalesInvLine.Amount));
        VerifyColumn15(RowNo + 1, FormatValue(SalesInvLine.Amount));
        VerifyColumn18(RowNo + 1, FormatValue(SalesInvLine."Amount Including VAT" - SalesInvLine.Amount));

        SalesInvLine.SetRange("VAT %", 0);
        SalesInvLine.FindFirst();
        VerifyColumn16(RowNo, FormatValue(SalesInvLine.Amount));
        VerifyColumn16(RowNo + 1, FormatValue(SalesInvLine.Amount));
        VerifyColumn19(RowNo, '');
    end;

    local procedure VerifyVATLedgExportBasic20FCY(InvNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        RowNo: Integer;
    begin
        RowNo := 19;
        GetSalesInvHeader(InvNo, SalesInvHeader, SalesInvLine);
        VerifyColumn12(RowNo, GetCurrDescription(SalesInvHeader."Currency Code"));
        VerifyColumn13a(RowNo, FormatValue(SalesInvLine."Amount Including VAT"));
        VerifyColumn13b(RowNo, FormatValue(SalesInvLine."Amount Including VAT (LCY)"));
        VerifyColumn14(RowNo, FormatValue(SalesInvLine."Amount (LCY)"));
        VerifyColumn14a(RowNo, '');
        VerifyColumn15(RowNo, '');
        VerifyColumn17(RowNo, FormatValue(SalesInvLine."Amount Including VAT (LCY)" - SalesInvLine."Amount (LCY)"));
        VerifyColumn17a(RowNo, '');
        VerifyColumn18(RowNo, '');
        VerifyColumn19(RowNo, '');
    end;

    local procedure VerifyVATLedgExportBasic18FCY(InvNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        RowNo: Integer;
    begin
        RowNo := 19;
        GetSalesInvHeader(InvNo, SalesInvHeader, SalesInvLine);
        VerifyColumn12(RowNo, GetCurrDescription(SalesInvHeader."Currency Code"));
        VerifyColumn13a(RowNo, FormatValue(SalesInvLine."Amount Including VAT"));
        VerifyColumn13b(RowNo, FormatValue(SalesInvLine."Amount Including VAT (LCY)"));
        VerifyColumn14(RowNo, '');
        VerifyColumn14a(RowNo, FormatValue(SalesInvLine."Amount (LCY)"));
        VerifyColumn15(RowNo, '');
        VerifyColumn17(RowNo, '');
        VerifyColumn17a(RowNo, FormatValue(SalesInvLine."Amount Including VAT (LCY)" - SalesInvLine."Amount (LCY)"));
        VerifyColumn18(RowNo, '');
        VerifyColumn19(RowNo, '');
    end;

    local procedure VerifyVATLedgExportConventionalRelational20(InvNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        RowNo: Integer;
    begin
        RowNo := 19;
        GetSalesInvHeader(InvNo, SalesInvHeader, SalesInvLine);
        VerifyColumn12(RowNo, '');
        VerifyColumn13a(RowNo, '');
        VerifyColumn13b(RowNo, FormatValue(SalesInvLine."Amount Including VAT (LCY)"));
        VerifyColumn14(RowNo, FormatValue(SalesInvLine."Amount (LCY)"));
    end;

    local procedure VerifyVATLedgExportConventionalRelational18(InvNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        RowNo: Integer;
    begin
        RowNo := 19;
        GetSalesInvHeader(InvNo, SalesInvHeader, SalesInvLine);
        VerifyColumn12(RowNo, '');
        VerifyColumn13a(RowNo, '');
        VerifyColumn13b(RowNo, FormatValue(SalesInvLine."Amount Including VAT (LCY)"));
        VerifyColumn14a(RowNo, FormatValue(SalesInvLine."Amount (LCY)"));
    end;

    local procedure VerifyVATLedgExportBasicAdvance(GenJnlLine: Record "Gen. Journal Line"; VATRate: Decimal)
    var
        GLEntry: Record "G/L Entry";
        Customer: Record Customer;
        Amt: Decimal;
        VATAmount: Decimal;
        RowNo: Integer;
    begin
        RowNo := 19;
        GLEntry.SetRange("External Document No.", GenJnlLine."Document No.");
        GLEntry.SetRange("Document Type", GenJnlLine."Document Type"::Invoice);
        GLEntry.FindLast();

        Customer.Get(GenJnlLine."Account No.");
        VerifyColumn3(RowNo, GLEntry."Document No." + '; ' + Format(GenJnlLine."Document Date"));
        VerifyColumn7(RowNo, Format(Customer.Name));
        VerifyVATLedgerExport_DocPdtvOpl(RowNo, GenJnlLine."Document No.", GenJnlLine."Document Date"); // Column 11

        Amt := Abs(GenJnlLine.Amount);
        VATAmount := Round(Amt * VATRate / (100 + VATRate), 0.01);
        VerifyColumn13a(RowNo, '');
        VerifyColumn13b(RowNo, FormatValue(Amt));
        VerifyColumn14(RowNo, '-');
        VerifyColumn17(RowNo, FormatValue(VATAmount));
        VerifyColumn19(RowNo, '');
    end;

    local procedure VerifyVATLedgExportCorrection(CorInvNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        RowNo: Integer;
    begin
        RowNo := 20;
        GetSalesInvHeader(CorInvNo, SalesInvHeader, SalesInvLine);
        VerifyColumn5(RowNo, SalesInvHeader."No." + '; ' + Format(SalesInvHeader."Document Date"));
        VerifyColumn13a(RowNo, '');
        VerifyColumn13b(RowNo, FormatValue(SalesInvHeader."Amount Including VAT"));
    end;

    local procedure VerifyVATLedgExportRevision(RevInvNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        RowNo: Integer;
    begin
        RowNo := 20;
        GetSalesInvHeader(RevInvNo, SalesInvHeader, SalesInvLine);
        VerifyColumn4(RowNo, SalesInvHeader."Revision No." + '; ' + Format(SalesInvHeader."Document Date"));
        VerifyColumn13a(RowNo, '');
        VerifyColumn13b(RowNo, FormatValue(SalesInvHeader."Amount Including VAT"));
    end;

    local procedure VerifyVATLedgExportRevOfCorr(CorInvNo: Code[20]; RevInvNo: Code[20])
    var
        CorSalesInvHeader: Record "Sales Invoice Header";
        CorSalesInvLine: Record "Sales Invoice Line";
        RevSalesInvHeader: Record "Sales Invoice Header";
        RevSalesInvLine: Record "Sales Invoice Line";
        RowNo: Integer;
    begin
        RowNo := 21;
        GetSalesInvHeader(CorInvNo, CorSalesInvHeader, CorSalesInvLine);
        GetSalesInvHeader(RevInvNo, RevSalesInvHeader, RevSalesInvLine);

        VerifyColumn5(RowNo, CorSalesInvHeader."No." + '; ' + Format(CorSalesInvHeader."Document Date"));
        VerifyColumn6(RowNo, RevSalesInvHeader."Revision No." + '; ' + Format(RevSalesInvHeader."Document Date"));
        VerifyColumn13a(RowNo, '');
        VerifyColumn13b(RowNo, FormatValue(RevSalesInvHeader."Amount Including VAT"));
    end;

    local procedure VerifyVATLedgExportVendorPrpmt(ExpectedCV: Text)
    begin
        VerifyCompanyVATRegNo(13, ExpectedCV);
    end;

    local procedure VerifyVATLedgExportAddSheetTwoPeriods(InvNo: array[2] of Code[20])
    begin
        // first period: row number 15
        VerifyExcelRowBasic20(InvNo[1], 15, 1);
        // second period: row number 40
        VerifyExcelRowBasic20(InvNo[2], 40, 1);
    end;

    local procedure VerifyVATLedgerExport_DocPdtvOpl(RowNo: Integer; ExpectedDocNo: Code[35]; ExpectedDocDate: Date)
    begin
        VerifyColumn11(RowNo, ExpectedDocNo + '; ' + Format(ExpectedDocDate));
    end;

    local procedure VerifyExcelRowBasic20(InvNo: Code[20]; RowNo: Integer; LineNo: Integer)
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
    begin
        GetSalesInvHeader(InvNo, SalesInvHeader, SalesInvLine);
        VerifyRepCommonValues(SalesInvHeader, RowNo, LineNo);

        VerifyColumn13a(RowNo, '');
        VerifyColumn13b(RowNo, FormatValue(SalesInvLine."Amount Including VAT"));
        VerifyColumn14(RowNo, FormatValue(SalesInvLine.Amount));
        VerifyColumn14a(RowNo, '');
        VerifyColumn15(RowNo, '');
        VerifyColumn16(RowNo, '');
        VerifyColumn17(RowNo, FormatValue(SalesInvLine."Amount Including VAT (LCY)" - SalesInvLine.Amount));
        VerifyColumn17a(RowNo, '');
        VerifyColumn18(RowNo, '');
        VerifyColumn19(RowNo, '');
    end;

    local procedure VerifyExcelRowBasic18(InvNo: Code[20]; RowNo: Integer; LineNo: Integer)
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
    begin
        GetSalesInvHeader(InvNo, SalesInvHeader, SalesInvLine);
        VerifyRepCommonValues(SalesInvHeader, RowNo, LineNo);

        VerifyColumn13a(RowNo, '');
        VerifyColumn13b(RowNo, FormatValue(SalesInvLine."Amount Including VAT"));
        VerifyColumn14(RowNo, '');
        VerifyColumn14a(RowNo, FormatValue(SalesInvLine.Amount));
        VerifyColumn15(RowNo, '');
        VerifyColumn16(RowNo, '');
        VerifyColumn17(RowNo, '');
        VerifyColumn17a(RowNo, FormatValue(SalesInvLine."Amount Including VAT (LCY)" - SalesInvLine.Amount));
        VerifyColumn18(RowNo, '');
        VerifyColumn19(RowNo, '');
    end;

    local procedure VerifyCompanyVATRegNo(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 50, ExpectedValue);
    end;

    local procedure VerifyColumn1(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 1, ExpectedValue);
    end;

    local procedure VerifyColumn2(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 5, ExpectedValue);
    end;

    local procedure VerifyColumn3(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 11, ExpectedValue);
    end;

    local procedure VerifyColumn3a(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 19, ExpectedValue);
    end;

    local procedure VerifyColumn4(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 26, ExpectedValue);
    end;

    local procedure VerifyColumn5(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 34, ExpectedValue);
    end;

    local procedure VerifyColumn6(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 42, ExpectedValue);
    end;

    local procedure VerifyColumn7(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 50, ExpectedValue);
    end;

    local procedure VerifyColumn9(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 77, ExpectedValue);
    end;

    local procedure VerifyColumn10(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 87, ExpectedValue);
    end;

    local procedure VerifyColumn11(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 89, ExpectedValue);
    end;

    local procedure VerifyColumn12(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 98, ExpectedValue);
    end;

    local procedure VerifyColumn13a(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 106, ExpectedValue);
    end;

    local procedure VerifyColumn13b(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 113, ExpectedValue);
    end;

    local procedure VerifyColumn14(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 120, ExpectedValue);
    end;

    local procedure VerifyColumn14a(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 126, ExpectedValue);
    end;

    local procedure VerifyColumn15(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 132, ExpectedValue);
    end;

    local procedure VerifyColumn16(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 138, ExpectedValue);
    end;

    local procedure VerifyColumn17(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 144, ExpectedValue);
    end;

    local procedure VerifyColumn17a(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 150, ExpectedValue);
    end;

    local procedure VerifyColumn18(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 156, ExpectedValue);
    end;

    local procedure VerifyColumn19(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 162, ExpectedValue);
    end;

    local procedure VerifyColumn20(RowNo: Integer; ExpectedValue: Text)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 173, ExpectedValue);
    end;
}

