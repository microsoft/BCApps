codeunit 147141 "ERM Purchase VAT Ledger Export"
{
    //   // [FEATURE] [VAT Ledger] [Purchase]
    // // Empty VersionList not to run tests in Snap

    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "VAT Entry" = imd;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRUReports: Codeunit "Library RU Reports";
        Assert: Codeunit Assert;
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        IsInitialized: Boolean;
        WrongVATLedgerLineCountErr: Label 'VAT Sales Ledger should contain only one line';
        SemicolonTok: Label '; ';

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic18()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO ID.1] Purchase Book Basic - VAT 18%
        Initialize();

        // [GIVEN] Create and post purchase invoice with new vendor VAT 18%
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2018(), false);

        // [WHEN] Run report Purchase VAT Ledger Export
        RunVATLedgerExportReport(VendorNo, false, false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyVATLedgExportBasic(InvNo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic20()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO 303035] Purchase Book Basic - VAT 20%
        Initialize();

        // [GIVEN] Create and post purchase invoice with new vendor VAT 20%
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2019(), false);

        // [WHEN] Run report Purchase VAT Ledger Export
        RunVATLedgerExportReport(VendorNo, false, false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount exported to the proper Excel cells
        VerifyVATLedgExportBasic(InvNo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic10()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO ID.3] Purchase Book Basic - VAT 10%
        Initialize();

        // [GIVEN] Create and post purchase invoice with new vendor VAT 10%
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', 10, false);

        // [WHEN] Run report Purchase VAT Ledger Export
        RunVATLedgerExportReport(VendorNo, false, false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyVATLedgExportBasic(InvNo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic18_10_0()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO ID.4] Purchase Book 18+10+0%
        Initialize();

        // [GIVEN] Create and post purchase invoice with 3 lines VAT 18%, 10% and 0%
        InvNo := CreateAndPostPurchInvoiceMultiLines(VendorNo, '', VATLedgerMgt.GetVATPctRate2018());

        // [WHEN] Run report Purchase VAT Ledger Export
        RunVATLedgerExportReport(VendorNo, false, false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyVATLedgExportBasic(InvNo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic20_10_0()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO 303035] Purchase Book 20+10+0%
        Initialize();

        // [GIVEN] Create and post purchase invoice with 3 lines VAT 20%, 10% and 0%
        InvNo := CreateAndPostPurchInvoiceMultiLines(VendorNo, '', VATLedgerMgt.GetVATPctRate2019());

        // [WHEN] Run report Purchase VAT Ledger Export
        RunVATLedgerExportReport(VendorNo, false, false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount exported to the proper Excel cells
        VerifyVATLedgExportBasic(InvNo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic18FCY()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO ID.5] Purchase Book FCY (VAT 18%)
        Initialize();

        // [GIVEN] Create and post purchase invoice with currency code
        InvNo := CreateAndPostPurchInvoice(VendorNo, CreateCurrency(false), VATLedgerMgt.GetVATPctRate2018(), false);

        // [WHEN] Run report Purchase VAT Ledger Export
        RunVATLedgerExportReport(VendorNo, false, false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyVATLedgExportFCY(InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic20FCY()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO 303035] Purchase Book FCY (VAT 20%)
        Initialize();

        // [GIVEN] Create and post purchase invoice with currency code
        InvNo := CreateAndPostPurchInvoice(VendorNo, CreateCurrency(false), VATLedgerMgt.GetVATPctRate2019(), false);

        // [WHEN] Run report Purchase VAT Ledger Export
        RunVATLedgerExportReport(VendorNo, false, false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount exported to the proper Excel cells
        VerifyVATLedgExportFCY(InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic18FCYConventional()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO 124073] Purchase Book Conventional Currency (VAT 18%)
        Initialize();

        // [GIVEN] Create and post purchase invoice "X" with conventional currency
        // [GIVEN] where "Amount Including VAT (LCY)" = "A", "Amount (LCY)" = "B".
        InvNo := CreateAndPostPurchInvoice(VendorNo, CreateCurrency(true), VATLedgerMgt.GetVATPctRate2018(), false);

        // [WHEN] Run report Purchase VAT Ledger Export
        RunVATLedgerExportReport(VendorNo, false, false);

        // [THEN] Column 14 value is empty
        // [THEN] Column 15 value equals "X"."A"
        // [THEN] Column 16 value equals "X"."A" - "X"."B"
        VerifyVATLedgExportConventionalRelational(InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic20FCYConventional()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO 124073] Purchase Book Conventional Currency (VAT 20%)
        Initialize();

        // [GIVEN] Create and post purchase invoice "X" with conventional currency
        // [GIVEN] where "Amount Including VAT (LCY)" = "A", "Amount (LCY)" = "B".
        InvNo := CreateAndPostPurchInvoice(VendorNo, CreateCurrency(true), VATLedgerMgt.GetVATPctRate2019(), false);

        // [WHEN] Run report Purchase VAT Ledger Export
        RunVATLedgerExportReport(VendorNo, false, false);

        // [THEN] Column 14 value is empty
        // [THEN] Column 15 value equals "X"."A"
        // [THEN] Column 16 value equals "X"."A" - "X"."B"
        VerifyVATLedgExportConventionalRelational(InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic18FCYRelationalCurr()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO 362467]  Purchase VAT Ledger Export Report for Purchase Invoice with FCY having Relational Currency Code (VAT 18%)
        Initialize();

        // [GIVEN] Posted Purchase Invoice with FCY having Relational Currency Code
        // [GIVEN] where "Amount Including VAT (LCY)" = 118, "Amount (LCY)" = 100
        InvNo := CreateAndPostPurchInvoice(VendorNo, CreateCurrWithRelationalCurrCode(), VATLedgerMgt.GetVATPctRate2018(), false);

        // [WHEN] Run report Purchase VAT Ledger Export
        RunVATLedgerExportReport(VendorNo, false, false);

        // [THEN] Column 14 value is empty
        // [THEN] Column 15 value equals 118
        // [THEN] Column 16 value equals 118 - 100 = 18
        VerifyVATLedgExportConventionalRelational(InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic20FCYRelationalCurr()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO 362467]  Purchase VAT Ledger Export Report for Purchase Invoice with FCY having Relational Currency Code (VAT 20%)
        Initialize();

        // [GIVEN] Posted Purchase Invoice with FCY having Relational Currency Code
        // [GIVEN] where "Amount Including VAT (LCY)" = 120, "Amount (LCY)" = 100
        InvNo := CreateAndPostPurchInvoice(VendorNo, CreateCurrWithRelationalCurrCode(), VATLedgerMgt.GetVATPctRate2019(), false);

        // [WHEN] Run report Purchase VAT Ledger Export
        RunVATLedgerExportReport(VendorNo, false, false);

        // [THEN] Column 14 value is empty
        // [THEN] Column 15 value equals 120
        // [THEN] Column 16 value equals 120 - 100 = 20
        VerifyVATLedgExportConventionalRelational(InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportAddSheet()
    var
        InvNo: Code[20];
        VendorNo: Code[20];
    begin
        // [SCENARIO ID.16] Purchase Book Basic with additional sheet
        Initialize();

        // [GIVEN] Create and post purchase invoice with additional sheet
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2019(), true);

        // [WHEN] Run report Purchase VAT Ledger Export
        RunVATLedgerExportReport(VendorNo, true, false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyVATLedgExportBasic(InvNo, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportCorrection()
    var
        InvNo: Code[20];
        VendorNo: Code[20];
        CorInvNo: Code[20];
    begin
        // [SCENARIO ID.17] Purchase Book with correction
        Initialize();

        // [GIVEN] Create and post purchase invoice with correction
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2019(), false);
        CorInvNo := CreatePostCorrRevPurchInvoice(VendorNo, InvNo, true);

        // [WHEN] Run report Purchase VAT Ledger Export
        RunVATLedgerExportReport(VendorNo, false, false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyVATLedgExportCorrection(CorInvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportRevision()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
        RevInvNo: Code[20];
    begin
        // [SCENARIO ID.18] Purchase Book with revision
        Initialize();

        // [GIVEN] Create and post purchase invoice with revision
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2019(), false);
        RevInvNo := CreatePostCorrRevPurchInvoice(VendorNo, InvNo, false);

        // [WHEN] Run report Purchase VAT Ledger Export
        RunVATLedgerExportReport(VendorNo, false, false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyVATLedgExportRevision(RevInvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportRevCorr()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
        CorInvNo: Code[20];
        RevInvNo: Code[20];
    begin
        // [SCENARIO ID.19] Purchase Book with revision for correction
        Initialize();

        // [GIVEN] Create and post purchase invoice with revision for correction
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2019(), false);
        CorInvNo := CreatePostCorrRevPurchInvoice(VendorNo, InvNo, true);
        RevInvNo := CreatePostCorrRevPurchInvoice(VendorNo, CorInvNo, false);

        // [WHEN] Run report Purchase VAT Ledger Export
        RunVATLedgerExportReport(VendorNo, false, false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount
        // exported to the  proper Excel cells
        VerifyVATLedgExportRevCorr(CorInvNo, RevInvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportImportFullVAT()
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        DocNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO 361962] Full VAT on import operation in Purchase VAT Ledger
        Initialize();

        // [GIVEN] Posted Purchase invoice "X" with Full VAT
        DocNo := CreateAndPostPurchInvoiceFullVAT(VendorNo, Amount, '', 0D);

        // [GIVEN] Payment "Y" applied to "X"
        CreatePostAndApplyGeneralLine(GenJnlLine, VendorNo, DocNo, Amount);

        // [WHEN] Export Purchase VAT Ledger to Excel
        RunVATLedgerExportReport(VendorNo, false, false);

        // [THEN] Column 3 value equals "X"."No."; "X"."Document Date"
        // [THEN] Column 7 value equals "Y"."No."; "Y"."Posting Date"
        // [THEN] Column 15 value equals "X"."Amount Incl. VAT (LCY)"
        // [THEN] Column 16 value equals "X"."Amount Incl. VAT (LCY)"
        VerifyVATLedgExportImportFullVAT(
          DocNo, CopyStr(GenJnlLine."External Document No.", 1, 20), GenJnlLine."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportImportFullVATExtDocNo()
    var
        GenJnlLine: Record "Gen. Journal Line";
        PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        DocNo: Code[20];
        VendVATInvNo: Code[30];
        VendorVATInvDate: Date;
        Amount: Decimal;
    begin
        // [SCENARIO 362667] Full VAT on import operation in Purchase VAT Ledger, Use External Doc No.
        Initialize();

        // [GIVEN] Posted Purchase invoice "X" with Full VAT
        // [GIVEN] "Vendor VAT Invoice No." = A, "Vendor VAT Invoice Date" = B
        VendVATInvNo :=
          PadStr(LibraryUtility.GenerateGUID(), MaxStrLen(PurchHeader."Vendor VAT Invoice No."), '0');
        VendorVATInvDate := LibraryRandom.RandDate(5);
        DocNo := CreateAndPostPurchInvoiceFullVAT(VendorNo, Amount, VendVATInvNo, VendorVATInvDate);

        // [GIVEN] Payment "Y" applied to "X"
        CreatePostAndApplyGenLineWithPostingDate(GenJnlLine, VendorNo, DocNo, Amount);

        // [WHEN] Export Purchase VAT Ledger to Excel, "Use External Doc. No." is set to TRUE
        RunVATLedgerExportReport(VendorNo, false, true);

        // [THEN] Column 3 value equals "A"; "B"
        // [THEN] Column 7 value equals "Y"."No."; "Y"."Posting Date"
        // [THEN] Column 15 value equals "X"."Amount Incl. VAT (LCY)"
        // [THEN] Column 16 value equals "X"."Amount Incl. VAT (LCY)"
        VerifyVATLedgExportImportFullVATExtDocNo(
          DocNo, GenJnlLine."Document No.", GenJnlLine."Posting Date", VendVATInvNo, VendorVATInvDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportImportFullVATTwoPayments()
    var
        VendorNo: Code[20];
        DocNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Full VAT] [Apply]
        // [SCENARIO 374725] Export VAT Purchase Ledger with two applied payments involving Full VAT
        Initialize();

        // [GIVEN] Posted Purchase Invoice with Full VAT
        DocNo := CreateAndPostPurchInvoiceFullVAT(VendorNo, Amount, '', 0D);

        // [GIVEN] Applied payment posted at date "11/01/2015" with "External Document No." = "NO1"
        // [GIVEN] Applied payment posted at date "21/01/2015" with "External Document No." = "NO2"
        PostTwoAppliedPayments(VendorNo, DocNo, Amount);

        // [WHEN] Export VAT Purchase Ledger in XML format
        RunVATLedgerExportReport(VendorNo, false, false);

        // [THEN] Row value in Column 7 = "NO1; 11/01/2015; NO2; 21/01/2015"
        VerifyVATLedgExportTwoPayments(VendorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportImportVATAgent()
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        DocNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO 362579] Purchase VAT Ledger with VAT Agent on import operation
        Initialize();

        // [GIVEN] Posted Purchase invoice "X" with Vendor is VAT Agent
        DocNo := CreateAndPostPurchInvoiceVATAgent(VendorNo, Amount, '', 0D);

        // [GIVEN] Payment "Y" applied to "X"
        CreatePostAndApplyGeneralLine(GenJnlLine, VendorNo, DocNo, Amount);
        // [GIVEN] Posted VAT Settlement Journal Line
        CreatePostVATSettlementJnlLine(VendorNo);

        // [WHEN] Export Purchase VAT Ledger to Excel
        RunVATLedgerExportReport(VendorNo, false, false);

        // [THEN] Column 7 value equals "Y"."External Document No."; "Y"."Posting Date"
        // [THEN] Column 15 value equals "X"."Amount Incl. VAT"
        // [THEN] Column 16 value equals "X"."Amount Incl. VAT (LCY)" + "Unrealised Amount"
        VerifyVATLedgExportImportVATAgent(DocNo, GenJnlLine."External Document No.", GenJnlLine."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATLedgerImportVATAgent()
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        DocNo: Code[20];
        VATLedgerCode: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 362579] Sales VAT Ledger with VAT Agent on import operation
        Initialize();

        // [GIVEN] Posted Purchase invoice "X" with Full VAT
        DocNo := CreateAndPostPurchInvoiceVATAgent(VendorNo, Amount, '', 0D);

        // [GIVEN] Payment "Y" applied to "X"
        PostAppliedPayment(GenJnlLine, VendorNo, DocNo, Amount, WorkDate());
        // [GIVEN] Posted VAT Settlement Journal Line
        CreatePostVATSettlementJnlLine(VendorNo);

        // [WHEN] Create Sales VAT Ledger Line
        VATLedgerCode :=
          LibrarySales.CreateSalesVATLedger(WorkDate(), LibraryRandom.RandDateFromInRange(WorkDate(), 5, 10), VendorNo);

        // [THEN] VAT Ledger contain only one line
        VerifySalesVATLedger(VendorNo, VATLedgerCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportVendorVATAgentNonResident()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Prepayment] [FCY] [VAT Agent]
        // [SCENARIO 374732] Export Purchase VAT Ledger for posted prepayment from foreign non-resident Vendor as VAT Agent with blank KPP Code and VAT Reg. No.
        Initialize();

        // [GIVEN] Foreign Non-Resident Vendor as VAT Agent "V" with blank
        // [GIVEN] "V"."KPP Code" = '' (blank)
        // [GIVEN] "V"."VAT Registration No." = '' (blank)
        CreatePurchInvoiceVATAgent(PurchaseHeader, VendorNo, Amount, '', 0D, true);
        Vendor.Get(VendorNo);
        Vendor.Validate("KPP Code", '');
        Vendor.Validate("VAT Registration No.", '');
        Vendor.Modify(true);

        // [GIVEN] Released Purchase Invoice "I" from Vendor "V"
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Posted Prepayment for the invoice "I"
        PurchaseHeader.CalcFields("Amount Including VAT");
        PostPrepayment(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", PurchaseHeader."No.", PurchaseHeader."Amount Including VAT");

        // [WHEN] Export Purchase VAT Ledger to XML
        RunVATLedgerExportReport(Vendor."No.", false, false);

        // [THEN] Exported CV "VAT Registration No." = "V"."VAT Registration No." (blank)
        // [THEN] "KPP Code" is not exported
        VerifyVATLedgExportCVCellValue('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportCustomerPrpmt()
    var
        SalesHeader: Record "Sales Header";
        CompanyType: Option Person,Organization;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 374736] Exported sales prepayment via VAT Purchase Ledger has company's VAT Reg No. and KPP Code
        Initialize();
        LibraryERM.SetCancelPrepmtAdjmtinTA(true);

        // [GIVEN] "Company Information"."VAT Registration No." = "X"
        // [GIVEN] "Company Information"."KPP Code" = "Y"
        LibraryRUReports.UpdateCompanyTypeInfo(CompanyType::Organization);

        // [GIVEN] Sales Invoice ("Posting Date" = "D1", "Amount Including VAT" = 1000, "VAT Amount" = 180) applied to Prepayment ("Posting Date" = "D2", Amount = 2000)
        CreateSalesInvoice(SalesHeader);
        PostAndApplySalesPrepayment(SalesHeader);

        // [WHEN] Export Purchase VAT Ledger to XML
        RunVATLedgerExportReport(SalesHeader."Sell-to Customer No.", false, false);

        // [THEN] Exported CV "VAT Registration No." = "Company Information"."VAT Registration No." = "X"
        // [THEN] Exported CV "KPP Code" = "Company Information"."KPP Code" = "Y"
        // [THEN] Exported "DataUcTov" (column 8) = "D1" (TFS 378574)
        // [THEN] Exported Amount Including VAT (column 15) = 2000 (TFS 379315)
        // [THEN] Exported VAT Amount (column 16) = 180 (TFS 379315)
        // [THEN] Exported Total VAT Amount (column 16, total) = 180 (TFS 379315)
        VerifyVATLedgExportCustomerPrepayment(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportAddSheetTwoPeriods()
    var
        VendorNo: Code[20];
        InvNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purch] [Additional sheet] Purchase Book add. sheet 2 periods
        Initialize();

        // [GIVEN] Create and post 2 purchase invoices with different periods
        PurchVATLedgerAddSheetTwoPeriodsScenario(VendorNo, InvNo);

        // [WHEN] Run report Purchase VAT Ledger Export
        RunVATLedgerExportReport(VendorNo, true, false);

        // [THEN] Verify Document Date, Amount Including VAT, Full VAT Amount exported to the proper Excel sheets
        VerifyVATLedgExportAddSheetTwoPeriods(InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportVendorVATAgentPrpmtOnInvoiceDate()
    var
        PrepaymentDate: Date;
        VendorNo: Code[20];
        AppliedAmount: Decimal;
    begin
        // [FEATURE] [Purch]
        // [SCENARIO 379551] VAT Purchase Ledger report in scenario with prepayment from VAT Agent on invoice date
        Initialize();
        LibraryERM.SetCancelPrepmtAdjmtinTA(true);
        DeleteVATEntriesOnDate(WorkDate(), WorkDate());

        // [GIVEN] Purchase Invoice and prepayment applied. Applied Amount = "X"
        CreateVATAgentPurchaseInvoiceAndAppliedPrepament(VendorNo, PrepaymentDate, AppliedAmount);

        // [WHEN] Export Purchase VAT Ledger to Excel on invoice date
        RunVATLedgerExportReportOnDate(VendorNo, WorkDate(), WorkDate(), false, false);

        // [THEN] Column 15 of line value equals "X".
        VerifyVATLedgExportVATAgentPrepayment(
          FormatValue(GetExpectedPrepaymentPurchVATLedgerAmountFCY(AppliedAmount, VATLedgerMgt.GetVATPctRate2019())));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportVendorVATAgentPrpmtOnPrepaymentDate()
    var
        PrepaymentDate: Date;
        VendorNo: Code[20];
        AppliedAmount: Decimal;
    begin
        // [FEATURE] [Purch]
        // [SCENARIO 379551] VAT Purchase Ledger report in scenario with prepayment from VAT Agent on prepayment date
        Initialize();
        LibraryERM.SetCancelPrepmtAdjmtinTA(true);
        DeleteVATEntriesOnDate(WorkDate(), WorkDate());

        // [GIVEN] Purchase Invoice and prepayment applied
        CreateVATAgentPurchaseInvoiceAndAppliedPrepament(VendorNo, PrepaymentDate, AppliedAmount);

        // [WHEN] Export Purchase VAT Ledger to Excel on prepayment date
        RunVATLedgerExportReportOnDate(VendorNo, PrepaymentDate, PrepaymentDate, false, false);

        // [THEN] There are no lines on Prepayment Date. Column 15 of line value is empty.
        VerifyVATLedgExportVATAgentPrepayment('');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        // "Posted VAT Agent No. Series" is blank in standard DB
        // We need keep the same series for the whole codeunit scope to avoid numbering conflict
        UpdatePostedVATAgentNoSeriesInPurchSetup(LibraryERM.CreateNoSeriesCode());

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Link Doc. Date To Posting Date", true);
        PurchasesPayablesSetup.Modify();

        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
    end;

    local procedure UpdateVATPostingSetupFullVAT(var VATPostingSetup: Record "VAT Posting Setup"; GLAccountNo: Code[20])
    begin
        VATPostingSetup."VAT %" := VATLedgerMgt.GetVATPctRate2019();
        VATPostingSetup."Purchase VAT Account" := GLAccountNo;
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Full VAT");
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateVATPostingSetupVATAgent(var VATPostingSetup: Record "VAT Posting Setup"; GLAccountNo: Code[20]; ManualVATSettlement: Boolean)
    begin
        VATPostingSetup."VAT %" := VATLedgerMgt.GetVATPctRate2019();
        VATPostingSetup."Purchase VAT Account" := GLAccountNo;
        VATPostingSetup."Purch. VAT Unreal. Account" := GLAccountNo;
        VATPostingSetup."Unrealized VAT Type" := VATPostingSetup."Unrealized VAT Type"::Percentage;
        VATPostingSetup."Manual VAT Settlement" := ManualVATSettlement;
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Modify(true);
    end;

    local procedure FindVATProdPostingGroup(var VATPostingSetup: Record "VAT Posting Setup"; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        VATPostingSetup.SetRange("VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
        VATPostingSetup.FindFirst();
    end;

    local procedure FormatValue(Value: Decimal): Text
    var
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        exit(LocalReportMgt.FormatReportValue(Value, 2));
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

    local procedure CreateVendor(var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    begin
        exit(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
    end;

    local procedure CreateVATAgentVendor(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(LibraryPurchase.CreateVendorVATAgent());
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("VAT Agent Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePurchHeader(var PurchHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, VendorNo);
    end;

    local procedure CreatePurchLine(var PurchHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryRUReports.CreatePurchaseLine(PurchLine, PurchHeader, VATPostingSetup);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019());
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibraryRUReports.UpdateCustomerPrepmtAccountVATRate(CustomerNo, VATLedgerMgt.GetVATPctRate2019());
        LibraryRUReports.CreateReleaseSalesInvoice(SalesHeader, VATPostingSetup, CustomerNo, '');
    end;

    local procedure CreatePurchLineWithGLAccount(var PurchHeader: Record "Purchase Header"; GLAccountNo: Code[20]; var Amount: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccountNo,
          LibraryRandom.RandDec(10, 2));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
        Amount := PurchLine."Amount Including VAT";
    end;

    local procedure UpdateCorrectionInfo(var PurchHeader: Record "Purchase Header"; CorrType: Option; CorrDocType: Option; CorrDocNo: Code[20])
    begin
        PurchHeader.Validate("Corrective Document", true);
        PurchHeader.Validate("Corrective Doc. Type", CorrType);
        PurchHeader.Validate("Corrected Doc. Type", CorrDocType);
        PurchHeader.Validate("Corrected Doc. No.", CorrDocNo);
        PurchHeader.Modify(true);
    end;

    local procedure UpdateRevisionInfo(var PurchHeader: Record "Purchase Header"; CorrDocType: Option; CorrDocNo: Code[20])
    begin
        UpdateCorrectionInfo(PurchHeader, PurchHeader."Corrective Doc. Type"::Revision, CorrDocType, CorrDocNo);
        PurchHeader.Validate("Revision No.", LibraryUtility.GenerateGUID());
        PurchHeader.Validate("Posting Date", CalcDate('<1D>', WorkDate()));
        PurchHeader.Modify(true);
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

    local procedure CopyDocument(PurchHeader: Record "Purchase Header"; DocNo: Code[20])
    var
        CopyPurchDocument: Report "Copy Purchase Document";
    begin
        CopyPurchDocument.SetPurchHeader(PurchHeader);
        CopyPurchDocument.SetParameters("Purchase Document Type From"::"Posted Invoice", DocNo, false, false);
        CopyPurchDocument.UseRequestPage(false);
        CopyPurchDocument.Run();
    end;

    local procedure RunVATLedgerExportReport(VendorNo: Code[20]; AddSheet: Boolean; UseExternalDocNo: Boolean)
    begin
        RunVATLedgerExportReportOnDate(
          VendorNo, WorkDate(), LibraryRandom.RandDateFromInRange(WorkDate(), 5, 10), AddSheet, UseExternalDocNo);
    end;

    local procedure RunVATLedgerExportReportOnDate(VendorNo: Code[20]; StartDate: Date; EndDate: Date; AddSheet: Boolean; UseExternalDocNo: Boolean)
    var
        VATLedgerCode: Code[20];
        FileName: Text[1024];
    begin
        VATLedgerCode :=
          LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, VendorNo, UseExternalDocNo, true);
        if AddSheet then
            LibraryPurchase.CreatePurchaseVATLedgerAddSheet(VATLedgerCode, 0);

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        FileName := LibraryReportValidation.GetFileName();

        LibraryPurchase.ExportPurchaseVATLedger(VATLedgerCode, AddSheet, FileName);
    end;

    local procedure CreateAndPostPurchInvoice(var VendorNo: Code[20]; CurrencyCode: Code[10]; VATRate: Decimal; AddSheet: Boolean) DocumentNo: Code[20]
    var
        PurchHeader: Record "Purchase Header";
    begin
        if AddSheet then
            DocumentNo := LibraryRUReports.CreatePostPurchaseInvoiceAddSheet(PurchHeader, CurrencyCode, VATRate)
        else
            DocumentNo := LibraryRUReports.CreatePostPurchaseInvoice(PurchHeader, CurrencyCode, VATRate);
        VendorNo := PurchHeader."Buy-from Vendor No.";
    end;

    local procedure CreateAndPostPurchInvoiceFullVAT(var VendorNo: Code[20]; var Amount: Decimal; VendVATInvNo: Code[30]; VendorVATInvDate: Date): Code[20]
    var
        PurchHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type", 0);
        GLAccountNo :=
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        UpdateVATPostingSetupFullVAT(VATPostingSetup, GLAccountNo);
        VendorNo :=
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        CreatePurchHeader(PurchHeader, VendorNo);
        LibraryRUReports.UpdatePurchaseHeaderWithVendorVATInvoiceInfo(PurchHeader, VendVATInvNo, VendorVATInvDate);
        CreatePurchLineWithGLAccount(PurchHeader, GLAccountNo, Amount);
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreatePurchInvoiceVATAgent(var PurchHeader: Record "Purchase Header"; var VendorNo: Code[20]; var Amount: Decimal; VendVATInvNo: Code[30]; VendorVATInvDate: Date; ManualVATSettlement: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type", 0);
        GLAccountNo :=
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        UpdateVATPostingSetupVATAgent(VATPostingSetup, GLAccountNo, ManualVATSettlement);
        VendorNo := CreateVATAgentVendor(VATPostingSetup);
        CreatePurchHeader(PurchHeader, VendorNo);
        LibraryRUReports.UpdatePurchaseHeaderWithVendorVATInvoiceInfo(PurchHeader, VendVATInvNo, VendorVATInvDate);
        CreatePurchLineWithGLAccount(PurchHeader, GLAccountNo, Amount);
    end;

    local procedure CreateAndPostPurchInvoiceVATAgent(var VendorNo: Code[20]; var Amount: Decimal; VendVATInvNo: Code[30]; VendorVATInvDate: Date): Code[20]
    var
        PurchHeader: Record "Purchase Header";
    begin
        CreatePurchInvoiceVATAgent(PurchHeader, VendorNo, Amount, VendVATInvNo, VendorVATInvDate, true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreateAndPostPurchInvoiceMultiLines(var VendorNo: Code[20]; CurrencyCode: Code[10]; NormalVATRate: Decimal): Code[20]
    begin
        exit(LibraryRUReports.CreatePostPurchaseInvoiceMultiLines(VendorNo, CurrencyCode, NormalVATRate));
    end;

    local procedure CreatePostCorrRevPurchInvoice(VendorNo: Code[20]; DocNo: Code[20]; Correction: Boolean): Code[20]
    var
        PurchHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreatePurchHeader(PurchHeader, VendorNo);
        if Correction then begin
            UpdateCorrectionInfo(
              PurchHeader, PurchHeader."Corrective Doc. Type"::Correction, PurchHeader."Corrected Doc. Type"::Invoice, DocNo);
            FindVATProdPostingGroup(VATPostingSetup, VendorNo);
            CreatePurchLine(PurchHeader, VATPostingSetup);
        end else begin
            UpdateRevisionInfo(PurchHeader, PurchHeader."Corrected Doc. Type"::Invoice, DocNo);
            CopyDocument(PurchHeader, DocNo);
        end;
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreatePaymentJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; AppliedInvoiceNo: Code[20]; AppliedAmount: Decimal; PostingDate: Date)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, AccountNo, AppliedAmount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliedInvoiceNo);
        GenJournalLine.Validate("Initial Document No.", AppliedInvoiceNo);
        GenJournalLine.Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePostAndApplyGeneralLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; DocNo: Code[20]; Amount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocNo);
        GenJournalLine.Validate("Initial Document No.", DocNo);
        GenJournalLine.Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostAndApplyGenLineWithPostingDate(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; DocNo: Code[20]; Amount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, AccountNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocNo);
        GenJournalLine."Posting Date" := LibraryRandom.RandDate(10);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostVATSettlementJnlLine(VendorNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", VendorNo);
        VATEntry.SetFilter("Unrealized Amount", '<>0');
        VATEntry.FindLast();
        CreateVATSettlementJnlLine(VATEntry);
    end;

    local procedure CreateVATSettlementJnlLine(VATEntry: Record "VAT Entry")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibraryRUReports.CreateVATSettlementTemplateAndBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, "Gen. Journal document Type"::" ",
            "Gen. Journal Account Type"::"G/L Account", '', 0);
        GenJnlLine.Validate("Unrealized VAT Entry No.", VATEntry."Entry No.");
        GenJnlLine.Validate("Posting Date", VATEntry."Posting Date");
        GenJnlLine.Validate(Amount, -VATEntry."Remaining Unrealized Amount");
        GenJnlLine.Validate("External Document No.", VATEntry."External Document No.");
        GenJnlLine.Modify();
        LibraryRUReports.PostVATSettlement(GenJnlBatch."Journal Template Name", GenJnlBatch.Name);
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

    local procedure CreatePrepaymentJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PrepDocNo: Code[20]; PrepaymentAmount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, AccountNo, PrepaymentAmount);
        GenJournalLine.Validate(Prepayment, true);
        GenJournalLine.Validate("Prepayment Document No.", PrepDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJnlBatchWithBalanceAccount(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"G/L Account";
        GenJournalBatch."Bal. Account No." := LibraryERM.CreateGLAccountNo();
        GenJournalBatch.Modify();
    end;

    local procedure CreateVATAgentPurchaseInvoiceAndAppliedPrepament(var VendorNo: Code[20]; var PrepaymentDate: Date; var AppliedAmount: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        Amount: Decimal;
    begin
        CreatePurchInvoiceVATAgent(PurchaseHeader, VendorNo, Amount, '', 0D, false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PostAndApplyPurchasePrepayment(PurchaseHeader, PrepaymentDate, AppliedAmount);
    end;

    local procedure PostPrepayment(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; InvoiceNo: Code[20]; PrepaymentAmount: Decimal)
    begin
        CreatePrepaymentJournalLine(GenJournalLine, AccountType, AccountNo, InvoiceNo, PrepaymentAmount);
        GenJournalLine.Validate("Posting Date", LibraryRandom.RandDate(-5));
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostAppliedPayment(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; AppliedInvoiceNo: Code[20]; AppliedAmount: Decimal; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);

        CreatePaymentJournalLine(
          GenJournalLine, GenJournalBatch, AccountNo, AppliedInvoiceNo, AppliedAmount, PostingDate);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostAndApplySalesPrepayment(var SalesHeader: Record "Sales Header")
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceNo: Code[20];
    begin
        // create and post prepayment
        SalesHeader.CalcFields("Amount Including VAT");
        PostPrepayment(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          SalesHeader."No.", -(SalesHeader."Amount Including VAT" + LibraryRandom.RandDecInDecimalRange(1000, 2000, 2)));

        // post invoice
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // post application
        LibraryERM.ApplyCustomerLedgerEntry(
          CustLedgerEntry."Document Type"::Invoice, InvoiceNo,
          CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
    end;

    local procedure PostTwoAppliedPayments(AccountNo: Code[20]; AppliedInvoiceNo: Code[20]; AppliedAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);

        CreatePaymentJournalLine(
          GenJournalLine, GenJournalBatch, AccountNo, AppliedInvoiceNo, Round(AppliedAmount / 3), LibraryRandom.RandDate(5));
        CreatePaymentJournalLine(
          GenJournalLine, GenJournalBatch, AccountNo, AppliedInvoiceNo, AppliedAmount - Round(AppliedAmount / 3), LibraryRandom.RandDate(5));

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostAndApplyPurchasePrepayment(var PurchaseHeader: Record "Purchase Header"; var PrepaymentDate: Date; var AppliedAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
    begin
        PurchaseHeader.CalcFields("Amount Including VAT");
        PostPrepayment(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
          PurchaseHeader."No.", PurchaseHeader."Amount Including VAT" / 2);

        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryERM.ApplyVendorLedgerEntries(
          VendorLedgerEntry."Document Type"::Invoice, VendorLedgerEntry."Document Type"::Payment,
          InvoiceNo, GenJournalLine."Document No.");

        PrepaymentDate := GenJournalLine."Posting Date";
        AppliedAmount := GenJournalLine.Amount;
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

    local procedure GetPurchInvHeader(InvNo: Code[20]; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchInvLine: Record "Purch. Inv. Line")
    begin
        PurchInvHeader.Get(InvNo);
        PurchInvHeader.CalcFields("Amount Including VAT", Amount);
        PurchInvLine.SetRange("Document No.", InvNo);
        PurchInvLine.FindFirst();
    end;

    local procedure GetSalesInvHeader(CustomerNo: Code[20]; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesInvoiceHeader.SetRange("Prepayment Invoice", false);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.CalcFields("Amount Including VAT", Amount);
    end;

    local procedure GetCustPrepaymentAmount(CustomerNo: Code[20]): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange(Prepayment, true);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount);
        exit(Abs(CustLedgerEntry.Amount));
    end;

    local procedure GetExpectedPrepaymentPurchVATLedgerAmountFCY(PaymentAmount: Decimal; VATPct: Decimal): Decimal
    begin
        exit(Round(PaymentAmount * (VATPct + 100) / 100));
    end;

    local procedure CalcVATAgentEntryAmount(VendorNo: Code[20]): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", VendorNo);
        VATEntry.SetFilter("Unrealized Amount", '<>0');
        if VATEntry.FindLast() then
            exit(VATEntry.Amount + VATEntry."Unrealized Amount");
    end;

    local procedure PurchVATLedgerAddSheetTwoPeriodsScenario(var VendorNo: Code[20]; var InvNo: array[2] of Code[20])
    var
        PurchHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATRate: Decimal;
    begin
        VATRate := VATLedgerMgt.GetVATPctRate2019();
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        VendorNo := CreateVendor(VATPostingSetup);
        CreatePurchHeader(PurchHeader, VendorNo);

        LibraryRUReports.UpdatePurchaseHeaderWithAddSheetInfo(PurchHeader, '<1M>');
        CreatePurchLine(PurchHeader, VATPostingSetup);
        InvNo[1] := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        CreatePurchHeader(PurchHeader, VendorNo);

        LibraryRUReports.UpdatePurchaseHeaderWithAddSheetInfo(PurchHeader, '<2M>');
        CreatePurchLine(PurchHeader, VATPostingSetup);
        InvNo[2] := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
    end;

    local procedure UpdatePostedVATAgentNoSeriesInPurchSetup(SeriesCode: Code[20])
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Posted VAT Agent Invoice Nos." := SeriesCode;
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure DeleteVATEntriesOnDate(StartDate: Date; EndDate: Date)
    var
        VATEntry: Record "VAT Entry";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
    begin
        VATLedgerMgt.SetVATPeriodFilter(VATEntry, StartDate, EndDate);
        VATEntry.DeleteAll();
    end;

    local procedure VerifyRepCommonValues(PurchInvHeader: Record "Purch. Inv. Header"; RowNo: Integer)
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(PurchInvHeader."Buy-from Vendor No.");
        LibraryReportValidation.VerifyCellValue(RowNo, 1, '1'); // Column 1
        LibraryReportValidation.VerifyCellValue(RowNo, 6, PurchInvHeader."VAT Entry Type"); // Column 2
        LibraryReportValidation.VerifyCellValue(
          RowNo, 14, PurchInvHeader."No." + '; ' + Format(PurchInvHeader."Document Date")); // Column 3
        VerifyVATLedgExportDataUcTov(RowNo, PurchInvHeader."Document Date"); // TFS 378574
        LibraryReportValidation.VerifyCellValue(RowNo, 68, Vendor.Name); // Column 9
        LibraryReportValidation.VerifyCellValue(RowNo, 79, ''); // Column 10
        LibraryReportValidation.VerifyCellValue(RowNo, 90, ''); // Column 11
        LibraryReportValidation.VerifyCellValue(RowNo, 125, ''); // Column 12
    end;

    local procedure VerifyVATLedgExportBasic(InvNo: Code[20]; AddSheet: Boolean)
    var
        RowNo: Integer;
    begin
        if AddSheet then
            RowNo := 15
        else
            RowNo := 19;
        VerifyExcelRowBasic(InvNo, RowNo);
    end;

    local procedure VerifyVATLedgExportFCY(InvNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        RowNo: Integer;
    begin
        RowNo := 19;
        GetPurchInvHeader(InvNo, PurchInvHeader, PurchInvLine);
        LibraryReportValidation.VerifyCellValue(
            RowNo, 125, GetCurrDescription(PurchInvHeader."Currency Code"));
        LibraryReportValidation.VerifyCellValue(
            RowNo, 126, FormatValue(PurchInvLine."Amount Including VAT")); // Column 15
        LibraryReportValidation.VerifyCellValue(
            RowNo, 142, FormatValue(PurchInvLine."Amount Including VAT (LCY)" - PurchInvLine."Amount (LCY)")); // Column 16
    end;

    local procedure VerifyVATLedgExportConventionalRelational(InvNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        RowNo: Integer;
    begin
        RowNo := 19;
        GetPurchInvHeader(InvNo, PurchInvHeader, PurchInvLine);
        LibraryReportValidation.VerifyCellValue(RowNo, 125, ''); // Column 14
        LibraryReportValidation.VerifyCellValue(
            RowNo, 126, FormatValue(PurchInvLine."Amount Including VAT (LCY)")); // Column 15
        LibraryReportValidation.VerifyCellValue(
            RowNo, 142, FormatValue(PurchInvLine."Amount Including VAT (LCY)" - PurchInvLine."Amount (LCY)")); // Column 16
    end;

    local procedure VerifyVATLedgExportCorrection(CorInvNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        RowNo: Integer;
    begin
        RowNo := 20;
        GetPurchInvHeader(CorInvNo, PurchInvHeader, PurchInvLine);
        LibraryReportValidation.VerifyCellValue(
            RowNo, 32, PurchInvHeader."No." + '; ' + Format(PurchInvHeader."Document Date")); // Column 5
        LibraryReportValidation.VerifyCellValue(
            RowNo, 126, FormatValue(PurchInvHeader."Amount Including VAT")); // Column 15
        LibraryReportValidation.VerifyCellValue(
            RowNo, 142, FormatValue(PurchInvHeader."Amount Including VAT" - PurchInvLine.Amount)); // Column 16
    end;

    local procedure VerifyVATLedgExportRevision(RevInvNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        RowNo: Integer;
    begin
        RowNo := 20;
        GetPurchInvHeader(RevInvNo, PurchInvHeader, PurchInvLine);
        LibraryReportValidation.VerifyCellValue(
            RowNo, 23, PurchInvHeader."Revision No." + '; ' + Format(PurchInvHeader."Document Date")); // Column 5
        LibraryReportValidation.VerifyCellValue(
            RowNo, 126, FormatValue(PurchInvHeader."Amount Including VAT")); // Column 15
        LibraryReportValidation.VerifyCellValue(
            RowNo, 142, FormatValue(PurchInvHeader."Amount Including VAT" - PurchInvHeader.Amount)); // Column 16
    end;

    local procedure VerifyVATLedgExportRevCorr(CorInvNo: Code[20]; RevInvNo: Code[20])
    var
        CorPurchInvHeader: Record "Purch. Inv. Header";
        CorPurchInvLine: Record "Purch. Inv. Line";
        RevPurchInvHeader: Record "Purch. Inv. Header";
        RevPurchInvLine: Record "Purch. Inv. Line";
        RowNo: Integer;
    begin
        RowNo := 21;
        GetPurchInvHeader(CorInvNo, CorPurchInvHeader, CorPurchInvLine);
        GetPurchInvHeader(RevInvNo, RevPurchInvHeader, RevPurchInvLine);

        LibraryReportValidation.VerifyCellValue(
            RowNo, 32, CorPurchInvHeader."No." + '; ' + Format(CorPurchInvHeader."Document Date")); // Column 5
        LibraryReportValidation.VerifyCellValue(
            RowNo, 41, RevPurchInvHeader."Revision No." + '; ' + Format(RevPurchInvHeader."Document Date")); // Column 5

        LibraryReportValidation.VerifyCellValue(
            RowNo, 126, FormatValue(RevPurchInvHeader."Amount Including VAT")); // Column 15
        LibraryReportValidation.VerifyCellValue(
            RowNo, 142, FormatValue(RevPurchInvHeader."Amount Including VAT" - RevPurchInvHeader.Amount)); // Column 16
    end;

    local procedure VerifyVATLedgExportImportFullVAT(InvNo: Code[20]; PayDocNo: Code[20]; PayDocDate: Date)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        RowNo: Integer;
    begin
        RowNo := 19;
        GetPurchInvHeader(InvNo, PurchInvHeader, PurchInvLine);
        VerifyRepCommonValues(PurchInvHeader, RowNo);
        LibraryReportValidation.VerifyCellValue(
            RowNo, 50, PayDocNo + '; ' + Format(PayDocDate)); // Column 7
        LibraryReportValidation.VerifyCellValue(
            RowNo, 126, FormatValue(PurchInvHeader."Amount Including VAT")); // Column 15
        LibraryReportValidation.VerifyCellValue(
            RowNo, 142, FormatValue(PurchInvHeader."Amount Including VAT" - PurchInvHeader.Amount)); // Column 16
    end;

    local procedure VerifyVATLedgExportImportFullVATExtDocNo(InvNo: Code[20]; PayDocNo: Code[20]; PayDocDate: Date; VendVATInvNo: Code[30]; VendorVATInvDate: Date)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        RowNo: Integer;
    begin
        RowNo := 19;
        GetPurchInvHeader(InvNo, PurchInvHeader, PurchInvLine);
        LibraryReportValidation.VerifyCellValue(
            RowNo, 14, VendVATInvNo + '; ' + Format(VendorVATInvDate)); // Column 3
        LibraryReportValidation.VerifyCellValue(
            RowNo, 50, PayDocNo + '; ' + Format(PayDocDate)); // Column 7
        LibraryReportValidation.VerifyCellValue(
            RowNo, 126, FormatValue(PurchInvHeader."Amount Including VAT")); // Column 15
        LibraryReportValidation.VerifyCellValue(
            RowNo, 142, FormatValue(PurchInvHeader."Amount Including VAT" - PurchInvHeader.Amount)); // Column 16
    end;

    local procedure VerifyVATLedgExportTwoPayments(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ExpectedValue: Text;
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.FindSet();
        repeat
            ExpectedValue += VendorLedgerEntry."External Document No." + SemicolonTok + Format(VendorLedgerEntry."Posting Date") + SemicolonTok;
        until VendorLedgerEntry.Next() = 0;
        ExpectedValue := DelChr(ExpectedValue, '>', SemicolonTok);

        LibraryReportValidation.VerifyCellValue(19, 50, ExpectedValue);
    end;

    local procedure VerifyVATLedgExportImportVATAgent(InvNo: Code[20]; PayDocNo: Code[35]; PayDocDate: Date)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        RowNo: Integer;
    begin
        RowNo := 19;
        GetPurchInvHeader(InvNo, PurchInvHeader, PurchInvLine);
        LibraryReportValidation.VerifyCellValue(
            RowNo, 50, PayDocNo + '; ' + Format(PayDocDate)); // Column 7
        LibraryReportValidation.VerifyCellValue(
            RowNo, 126, FormatValue(PurchInvHeader."Amount Including VAT")); // Column 15
        LibraryReportValidation.VerifyCellValue(
            RowNo, 142, FormatValue(CalcVATAgentEntryAmount(PurchInvHeader."Buy-from Vendor No."))); // Column 16
    end;

    local procedure VerifyVATLedgExportCVCellValue(ExpectedCV: Text)
    begin
        LibraryReportValidation.VerifyCellValue(19, 79, UpperCase(ExpectedCV));
    end;

    local procedure VerifySalesVATLedger(VendorNo: Code[20]; VATLedgerCode: Code[20])
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.SetRange(Type, VATLedger.Type::Sales);
        VATLedgerLine.SetRange(Code, VATLedgerCode);
        VATLedgerLine.SetRange("C/V No.", VendorNo);
        Assert.AreEqual(1, VATLedgerLine.Count, WrongVATLedgerLineCountErr);
    end;

    local procedure VerifyVATLedgExportAddSheetTwoPeriods(InvNo: array[2] of Code[20])
    begin
        // first period: row number 15
        VerifyExcelRowBasic(InvNo[1], 15);
        // second period: row number 41
        VerifyExcelRowBasic(InvNo[2], 41);
    end;

    local procedure VerifyVATLedgExportDataUcTov(RowNo: Integer; ExpectedDate: Date)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 59, Format(ExpectedDate)); // Column 8
    end;

    local procedure VerifyExcelRowBasic(InvNo: Code[20]; RowNo: Integer)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        GetPurchInvHeader(InvNo, PurchInvHeader, PurchInvLine);
        VerifyRepCommonValues(PurchInvHeader, RowNo);
        VerifyExcelRowBasicAmount(
          RowNo, PurchInvHeader."Amount Including VAT", PurchInvHeader."Amount Including VAT" - PurchInvHeader.Amount);
    end;

    local procedure VerifyExcelRowBasicAmount(RowNo: Integer; Amount: Decimal; VATAmount: Decimal)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 126, FormatValue(Amount)); // Column 15
        LibraryReportValidation.VerifyCellValue(RowNo, 142, FormatValue(VATAmount)); // Column 16
        LibraryReportValidation.VerifyCellValue(RowNo + 1, 142, FormatValue(VATAmount)); // Total Column 16
    end;

    local procedure VerifyVATLedgExportCustomerPrepayment(SalesHeader: Record "Sales Header")
    var
        CompanyInformation: Record "Company Information";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RowNo: Integer;
    begin
        CompanyInformation.Get();
        RowNo := 19;
        VerifyVATLedgExportCVCellValue(CompanyInformation."VAT Registration No." + ' / ' + CompanyInformation."KPP Code");
        VerifyVATLedgExportDataUcTov(RowNo, SalesHeader."Posting Date");

        GetSalesInvHeader(SalesHeader."Sell-to Customer No.", SalesInvoiceHeader);
        VerifyExcelRowBasicAmount(
          RowNo,
          GetCustPrepaymentAmount(SalesHeader."Sell-to Customer No."),
          SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount);
    end;

    local procedure VerifyVATLedgExportVATAgentPrepayment(AmountText: Text)
    begin
        LibraryReportValidation.VerifyCellValue(19, 126, AmountText);
    end;
}

