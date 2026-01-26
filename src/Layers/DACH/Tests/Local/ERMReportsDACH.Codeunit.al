codeunit 142062 "ERM Reports DACH"
{
    //   // [FEATURE] [Reports]
    //   1. Test and verify G/L Setup and Company Data Consolidation on G/L Setup Information Report.
    //   2. Test and verify Posting Groups on G/L Setup Information Report.
    //   3. Test and verify Posting Matrix on G/L Setup Information Report.
    //   4. Test and verify VAT Setup on G/L Setup Information Report.
    //   5. Test and verify Source Code Setup on G/L Setup Information Report.
    //   6. Test and verify Provisional Trial Balance Report.
    //   7. Test and verify Inventory Value (Help Report) Report.
    //   8. Test and verify Item ABC Analysis Report.
    //   9. Test and verify Vendor Payments List report with Standard Layout and Vendor Sorting.
    //  10. Test and verify Vendor Payments List report with FCY Amount Layout and Chronological Sorting.
    //  11. Test and verify Vendor Payments List report after applying Invoice to Payment of Vendor ledger entry.
    //  12. Test and verify Total Amount On Vendor Payments List report after applying Multiple Invoice to Payment of Vendor ledger entry.
    //  13. Test and verify Applies To Doc No. On Vendor Payments List report after applying two Invoice to Payment of Vendor ledger entry.
    // 
    //   Covers Test Cases for WI - 326840
    //   -----------------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                                   TFS ID
    //   -----------------------------------------------------------------------------------------------------------
    //   GLSetupAndCompanyDataConsolidationInformation, PostingGroupsOnGLSetupInformation                     151823
    //   PostingMatrixOnGLSetupInformation, VATSetupOnGLSetupInformation                                      151823
    //   SourceCodeSetupOnGLSetupInformation                                                                  151823
    //   ProvisionalTrialBalanceReport                                                                        151819
    //   InventoryValueReport                                                                                 151826
    //   ItemABCAnalysisReport                                                                                151820
    // 
    //   Covers Test Cases for WI - 326843
    //   -----------------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                                   TFS ID
    //   -----------------------------------------------------------------------------------------------------------
    //   VendorPaymentsListReportWithStandardLayout                                                           153137
    //   VendorPaymentsListReportWithFCYAmountLayout                                                          153138
    //   VendorPaymentsListReportWithApplyVendorEntry                                                  153139,151821
    // 
    //   Covers Test Cases for DACH - 46958
    //   -----------------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                                   TFS ID
    //   -----------------------------------------------------------------------------------------------------------
    //   CheckTotalAmtOnVendorPaymentList
    // 
    //   Covers Test Cases for DACH - 50470
    //   -----------------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                                   TFS ID
    //   -----------------------------------------------------------------------------------------------------------
    //   CheckAppliesToDocNoOnVendorPaymentListReport

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        RowNotFound: Label 'There is no dataset row corresponding to Element Name %1 with value %2', Comment = '%1=Field Caption;%2=Field Value';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';

    [Test]
    [HandlerFunctions('GLSetupInformationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLSetupAndCompanyDataConsolidationInformation()
    var
        SetupInformation: Option "G/L Setup - Company Data - Consolidation","Posting Groups","Posting Matrix","VAT Setup","Source Code - Reason Code","Check Number Series";
    begin
        // Setup.
        Initialize();

        // Exercise.
        RunGLSetupInformation(SetupInformation::"G/L Setup - Company Data - Consolidation");

        // Verify.
        VerifyGLSetupCompanyDataConsolidation();
    end;

    [Test]
    [HandlerFunctions('GLSetupInformationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostingGroupsOnGLSetupInformation()
    var
        SetupInformation: Option "G/L Setup - Company Data - Consolidation","Posting Groups","Posting Matrix","VAT Setup","Source Code - Reason Code","Check Number Series";
    begin
        // Setup.
        Initialize();

        // Exercise.
        RunGLSetupInformation(SetupInformation::"Posting Groups");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyCustomerPostingGroupOnGLSetupInformation();
        VerifyVendorPostingGroupOnGLSetupInformation();
        VerifyInventoryPostingGroupOnGLSetupInformation();
        VerifyBankAccountPostingGroupOnGLSetupInformation();
    end;

    [Test]
    [HandlerFunctions('GLSetupInformationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostingMatrixOnGLSetupInformation()
    var
        SetupInformation: Option "G/L Setup - Company Data - Consolidation","Posting Groups","Posting Matrix","VAT Setup","Source Code - Reason Code","Check Number Series";
    begin
        // Setup.
        Initialize();

        // Exercise.
        RunGLSetupInformation(SetupInformation::"Posting Matrix");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyGenBusinessPostingGroupOnGLSetupInformation();
        VerifyGenProductPostingGroupOnGLSetupInformation();
        VerifyGeneralPostingSetupOnGLSetupInformation();
    end;

    [Test]
    [HandlerFunctions('GLSetupInformationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATSetupOnGLSetupInformation()
    var
        SetupInformation: Option "G/L Setup - Company Data - Consolidation","Posting Groups","Posting Matrix","VAT Setup","Source Code - Reason Code","Check Number Series";
    begin
        // Setup.
        Initialize();

        // Exercise.
        RunGLSetupInformation(SetupInformation::"VAT Setup");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyVATBusinessPostingGroupOnGLSetupInformation();
        VerifyVATProductPostingGroupOnGLSetupInformation();
        VerifyVATPostingSetupOnGLSetupInformation();
    end;

    [Test]
    [HandlerFunctions('GLSetupInformationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SourceCodeSetupOnGLSetupInformation()
    var
        SetupInformation: Option "G/L Setup - Company Data - Consolidation","Posting Groups","Posting Matrix","VAT Setup","Source Code - Reason Code";
    begin
        // Setup.
        Initialize();

        // Exercise.
        RunGLSetupInformation(SetupInformation::"Source Code - Reason Code");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifySourceCodeOnGLSetupInformation();
        VerifySourceCodeSetupOnGLSetupInformation();
    end;

    [Test]
    [HandlerFunctions('ProvisionalTrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProvisionalTrialBalanceReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup: Create General Journal Line.
        Initialize();
        CreateGeneralJournalLine(GenJournalLine);

        // Exercise.
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");  // Enqueue for ProvisionalTrialBalanceRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");  // Enqueue for ProvisionalTrialBalanceRequestPageHandler.
        Commit();  // Commit required for ProvisionalTrialBalanceRequestPageHandler.
        REPORT.Run(REPORT::"Provisional Trial Balance");

        // Verify.
        VerifyProvisionalTrialBalance(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('InventoryValueRequestPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValueReport()
    var
        ItemJournalLine: Record "Item Journal Line";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // [FEATURE] [SCM] [Inventory Value]
        // [SCENARIO 379976] Inventory Value Report should correct illustrate expected cost and total cost after posting item journal line and purchase receipt.
        Initialize();

        // [GIVEN] Create and post Item Journal Line, "Cost Amount (Expected)" = 0, "Cost Amount (Actual)" = "X".
        CreateItem(Item);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.");

        // [GIVEN]  Create Purchase Order and post purchase receipt, "Cost Amount (Expected)" = "Y", "Cost Amount (Actual)" = 0.
        CreatePurchaseOrderPostReceipt(PurchaseLine, Item);

        // [GIVEN] Post Inventory Cost to G/L.
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [WHEN] Run Inventory Value report
        RunInventoryValue(ItemJournalLine."Item No.");

        // [THEN] "Cost Amount (Expected)" = "Y", "Cost Amount (Actual)" = "X", "Cost Amount (Total)" = "X" + "Y" in Inventory Value Report.
        VerifyInventoryValueAndPostingGroup(
          ItemJournalLine, ItemJournalLine.Quantity + PurchaseLine.Quantity,
          ItemJournalLine.Quantity, PurchaseLine.Amount, ItemJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('InventoryValueRequestPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValueReportWithDiffrentPostingGroup()
    var
        ItemJournalLine: array[2] of Record "Item Journal Line";
        Item: array[2] of Record Item;
        PurchaseLine: array[2] of Record "Purchase Line";
    begin
        // [FEATURE] [SCM] [Inventory Value]
        // [SCENARIO 379976] Inventory Value Report should correct illustrate expected cost and total cost after posting item journal line and purchase receipt for diffrent inventory posting groups.
        Initialize();

        // [GIVEN] Create and post Item Journal Line for first item, "Cost Amount (Expected)" = 0, "Cost Amount (Actual)" = "X".
        CreateItemWithInventoryPostingGroup(Item[1]);
        CreateAndPostItemJournalLine(ItemJournalLine[1], Item[1]."No.");

        // [GIVEN] Create Purchase Order and post purchase receipt for first item, "Cost Amount (Expected)" = "Y", "Cost Amount (Actual)" = 0.
        CreatePurchaseOrderPostReceipt(PurchaseLine[1], Item[1]);

        // [GIVEN] Create and post Item Journal Line for second item, "Cost Amount (Expected)" = 0, "Cost Amount (Actual)" = "Z".
        CreateItemWithInventoryPostingGroup(Item[2]);
        CreateAndPostItemJournalLine(ItemJournalLine[2], Item[2]."No.");

        // [GIVEN] Create Purchase Order and post purchase receipt for second item, "Cost Amount (Expected)" = "E", "Cost Amount (Actual)" = 0.
        CreatePurchaseOrderPostReceipt(PurchaseLine[2], Item[2]);

        // [GIVEN] Post Inventory Cost to G/L.
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [WHEN] Run Inventory Value report
        RunInventoryValue(Item[1]."No." + '|' + Item[2]."No.");

        // [THEN] "Cost Amount (Expected)" = "Y", "Cost Amount (Actual)" = "X", "Cost Amount (Total)" = "X" + "Y" in Inventory Value Report for first inventory posting group.
        // [THEN] "Cost Amount (Expected)" = "E", "Cost Amount (Actual)" = "Z", "Cost Amount (Total)" = "E" + "Z" in Inventory Value Report for second inventory posting group.
        VerifyInventoryValueWithDiffrentPostingGroup(
          Item[1]."Inventory Posting Group",
          Item[2]."Inventory Posting Group", ItemJournalLine[1].Amount, PurchaseLine[1].Amount,
          ItemJournalLine[2].Amount, PurchaseLine[2].Amount);
    end;

    [Test]
    [HandlerFunctions('InventoryValueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValueReportStatusDateBetweenReceiptAndInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // [FEATURE] [SCM] [Inventory Value]
        // [SCENARIO 379976] Inventory valuation report should include cost amount posted on status date and skip amount on later date

        Initialize();

        // [GIVEN] Item "I" with unit cost = "X"
        CreateItem(Item);

        // [GIVEN] Post purchase receipt of "N" items on workdate
        CreatePurchaseOrderPostReceipt(PurchaseLine, Item);

        // [GIVEN] Completely invoice purchase on WorkDate() + 1
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PostPurchaseInvoiceOnDate(PurchaseHeader, PurchaseHeader."Posting Date" + 1);

        // [WHEN] Run "Inventory Value" report on workdate
        RunInventoryValue(Item."No.");

        // [THEN] "Quantity Invoiced" = 0, expected cost amount = "X" * "N", actual cost amount = 0, total cost amount = "X" * "N"
        VerifyInventoryValue(Item."No.", PurchaseLine.Quantity, 0, PurchaseLine."Line Amount", 0);
    end;

    [Test]
    [HandlerFunctions('InventoryValueRequestPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValueReportPartiallyInvoicedOnStatusDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // [FEATURE] [SCM] [Inventory Value]
        // [SCENARIO 379976] Inventory valuation report should include cost amount posted on status date and skip amount on later date when puchase document is partially invoiced on different dates

        Initialize();

        // [GIVEN] Item "I" with unit cost = 100
        CreateItem(Item);

        // [GIVEN] Post purchase receipt of 10 pcs of item "I" on workdate
        CreatePurchaseOrderPostReceipt(PurchaseLine, Item);

        // [GIVEN] Partially invoice purchase on workdate. Invoiced quantity = 6
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseLine.Validate("Qty. to Invoice", LibraryRandom.RandInt(PurchaseLine.Quantity - 1));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Invoice remaining 4 pcs on WorkDate() + 1
        PurchaseLine.Find();
        PostPurchaseInvoiceOnDate(PurchaseHeader, PurchaseHeader."Posting Date" + 1);

        // [GIVEN] Post cost to G/L
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [WHEN] Run "Inventory Value" report on workdate
        RunInventoryValue(Item."No.");

        // [THEN] Quantity = 10, Invoiced quantity = 6, expected cost amount = 4 * 100, actual cost amount = 6 * 100, cost posted to g/l = 6 * 100
        VerifyInventoryValue(
          Item."No.", PurchaseLine.Quantity, PurchaseLine."Quantity Invoiced",
          Item."Unit Cost" * PurchaseLine."Qty. to Invoice", Item."Unit Cost" * PurchaseLine."Quantity Invoiced");
    end;

    [Test]
    [HandlerFunctions('ItemABCAnalysisRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemABCAnalysisReport()
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        // Setup: Create and post Item Journal Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.");

        // Exercise.
        LibraryVariableStorage.Enqueue(ItemJournalLine."Item No.");  // Enqueue for ItemABCAnalysisRequestPageHandler.
        REPORT.Run(REPORT::"Item ABC Analysis");

        // Verify.
        VerifyItemABCAnalysis(ItemJournalLine);
    end;

    [Test]
    [HandlerFunctions('VendorPaymentsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorPaymentsListReportWithStandardLayout()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Sorting: Option Vendor,Chronological;
        "Layout": Option Standard,"FCY Amounts","Posting Info";
    begin
        // Setup: Create Vendor. Create and post Payment Journal line.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostPaymentJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, Vendor."No.", LibraryRandom.RandDec(10, 2), '');

        // Exercise.
        RunVendorPaymentsListReport(Sorting::Vendor, Layout::Standard, Vendor."No.");

        // Verify.
        VerifyVendorPaymentListReportWithStandardLayout(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('VendorPaymentsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorPaymentsListReportWithFCYAmountLayout()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Sorting: Option Vendor,Chronological;
        "Layout": Option Standard,"FCY Amounts","Posting Info";
    begin
        // Setup: Create Vendor. Create Currency with Exchange rate. Create and post Payment Journal line.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        CreateAndPostPaymentJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, Vendor."No.", LibraryRandom.RandDec(10, 2),
          CurrencyExchangeRate."Currency Code");

        // Exercise.
        RunVendorPaymentsListReport(Sorting::Chronological, Layout::"FCY Amounts", Vendor."No.");

        // Verify.
        VerifyVendorPaymentListReportWithFCYAmountLayout(GenJournalLine, CurrencyExchangeRate);
    end;

    [Test]
    [HandlerFunctions('VendorPaymentsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorPaymentsListReportWithApplyVendorEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Sorting: Option Vendor,Chronological;
        "Layout": Option Standard,"FCY Amounts","Posting Info";
    begin
        // Setup: Create Vendor. Create and post Invoice and Payment for the Vendor. Apply Invoice to the Payment.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostPaymentJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, Vendor."No.", -LibraryRandom.RandDec(10, 2), '');
        CreateAndPostPaymentJournalLine(GenJournalLine2, GenJournalLine2."Document Type"::Payment, Vendor."No.", -GenJournalLine.Amount, '');
        ApplyAndPostVendorEntry(GenJournalLine2, GenJournalLine."Document No.");

        // Exercise.
        RunVendorPaymentsListReport(Sorting::Vendor, Layout::Standard, Vendor."No.");

        // Verify.
        VerifyVendorPaymentListReportWithApplicationEntry(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('VendorPaymentsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckTotalAmtOnVendorPaymentList()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        Sorting: Option Vendor,Chronological;
        "Layout": Option Standard,"FCY Amounts","Posting Info";
        Counter: Integer;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TotalDiscLCY: Decimal;
        TotalAmountLCY: Decimal;
        VendorNo: Code[20];
    begin
        // Setup: Create Vendor and create and post Multiple invoice and payment for the Vendor. Apply Invoice to the Payment.
        Initialize();
        VendorNo := CreateVendorWithPmtTerms();

        for Counter := 1 to LibraryRandom.RandIntInRange(2, 4) do begin
            CreateAndPostPaymentJournalLine(
              GenJournalLine, GenJournalLine."Document Type"::Invoice, VendorNo, -LibraryRandom.RandDec(10, 2), '');
            LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
            CreateAndPostPaymentJournalLine(GenJournalLine2, GenJournalLine2."Document Type"::Payment, VendorNo, -GenJournalLine.Amount, '');
            ApplyAndPostVendorEntry(GenJournalLine2, GenJournalLine."Document No.");
            TotalDiscLCY += VendorLedgerEntry."Original Pmt. Disc. Possible";
            TotalAmountLCY += GenJournalLine.Amount;
        end;

        // Exercise: Run the Report Vendor Payments List
        RunVendorPaymentsListReport(Sorting::Vendor, Layout::Standard, VendorNo);

        // Verify: Total Amount on Report
        VerifyTotalAmtOnVendorPaymentList(TotalAmountLCY, TotalDiscLCY);
    end;

    [Test]
    [HandlerFunctions('VendorPaymentsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckAppliesToDocNoOnVendorPaymentListReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        Sorting: Option Vendor,Chronological;
        "Layout": Option Standard,"FCY Amounts","Posting Info";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Test and verify Applies To Doc No. On Vendor Payments List report after applying two Invoice to Payment of Vendor ledger entry.

        // Setup: Create Vendor,Create and post invoice and payment then apply invoice to the Payment.
        Initialize();
        CreateAndPostMultipleVendorInvoices(GenJournalLine, DocumentNo, Amount);
        CreateAndPostPaymentJournalLine(
          GenJournalLine2, GenJournalLine2."Document Type"::Payment, GenJournalLine."Account No.", -(Amount + GenJournalLine.Amount), '');
        ApplyAndPostVendorEntryWithInvoices(
          GenJournalLine2."Document No.", GenJournalLine2.Amount, GenJournalLine."Document No.", DocumentNo);

        // Exercise: Run the Report Vendor Payments List.
        RunVendorPaymentsListReport(Sorting::Vendor, Layout::Standard, GenJournalLine."Account No.");

        // Verify: Verifying Applies to Doc No. on vendor payment list report.
        VerifyAppliestoDocNoOnVendorPaymentList(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('VendorPaymentsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalVendorAmountWithTwoPaymentsWhenOneIsAppliedToSevInvoices()
    var
        VendorNo: Code[20];
        InvoiceDocNo: array[3] of Code[20];
        PaymentDocNo: array[2] of Code[20];
        InvoiceAmount: array[2] of Decimal;
        PaymentAmount: array[2] of Decimal;
        Sorting: Option Vendor,Chronological;
        "Layout": Option Standard,"FCY Amounts","Posting Info";
    begin
        // [FEATURE] [Vendor Payments List]
        // [SCENARIO 380010] "Total Vendor" has correct amount value (pmt1 + pmt2) in case of two payments when first is applied to two invoices and second is open
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Two vendor Invoices: "Inv1" with Amount = "X1", "Inv2" with Amount = "X2"
        CreateAndPostVendorInvoice(VendorNo, InvoiceDocNo[1], InvoiceAmount[1]);
        CreateAndPostVendorInvoice(VendorNo, InvoiceDocNo[2], InvoiceAmount[2]);
        // [GIVEN] First payment "Pmt1" with Amount = "Y1" = "X1" + "X2", applied to two Invoices "Inv1", "Inv2"
        PaymentAmount[1] := InvoiceAmount[1] + InvoiceAmount[2];
        CreateAndPostVendorPayment(VendorNo, PaymentDocNo[1], PaymentAmount[1]);
        ApplyAndPostVendorEntryWithInvoices(PaymentDocNo[1], PaymentAmount[1], InvoiceDocNo[1], InvoiceDocNo[2]);
        // [GIVEN] Second payment "Pmt2" with Amount = "Y2"
        PaymentAmount[2] := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CreateAndPostVendorPayment(VendorNo, PaymentDocNo[2], PaymentAmount[2]);

        // [WHEN] Run "Vendor Payments List" report
        RunVendorPaymentsListReport(Sorting::Vendor, Layout::Standard, VendorNo);

        // [THEN] Total Vendor Amount = "Y1" + "Y2"
        LibraryReportDataset.LoadDataSetFile();
        VerifyVendorLedgerEntryAmount(1, PaymentAmount[1]);
        VerifyVendorLedgerEntryAmount(2, 0);
        VerifyVendorLedgerEntryAmount(3, PaymentAmount[2]);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Reports DACH");

        LibraryVariableStorage.Clear();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Reports DACH");
        NoSeriesSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Reports DACH");
    end;

    local procedure NoSeriesSetup()
    var
        PurchaseSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        PurchaseSetup.Get();
        PurchaseSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchaseSetup.Modify(true);

        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);
    end;

    local procedure ApplyAndPostVendorEntry(GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        SetApplyingVendorEntryForPayment(VendorLedgerEntry, GenJournalLine."Document No.", GenJournalLine.Amount);
        ApplytVendorEntryInvoice(DocumentNo);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure ApplyAndPostVendorEntryWithInvoices(PaymentDocNo: Code[20]; PaymentAmount: Decimal; FirstInvoiceDocumentNo: Code[20]; SecondInvoiceDocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        SetApplyingVendorEntryForPayment(VendorLedgerEntry, PaymentDocNo, PaymentAmount);
        ApplytVendorEntryInvoice(FirstInvoiceDocumentNo);
        ApplytVendorEntryInvoice(SecondInvoiceDocumentNo);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure ApplytVendorEntryInvoice(DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
    end;

    local procedure CreateAndPostPaymentJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10]): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreatePaymentJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Purchase, ItemNo, LibraryRandom.RandDec(100, 2));
        ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandDec(100, 2));
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateCurrencyWithExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(10, 2));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDec(10, 2));
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreatePaymentJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        BankAccount: Record "Bank Account";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.FindFirst();
        LibraryERM.FindBankAccount(BankAccount);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateAndPostMultipleVendorInvoices(var GenJournalLine: Record "Gen. Journal Line"; var DocumentNo: Code[20]; var Amount: Decimal)
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostPaymentJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, Vendor."No.", -LibraryRandom.RandDec(10, 2), '');
        DocumentNo := GenJournalLine."Document No.";
        Amount := GenJournalLine.Amount;
        CreateAndPostPaymentJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, Vendor."No.", -LibraryRandom.RandDec(10, 2), '');
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        Item.Modify(true);
    end;

    local procedure CreateItemWithInventoryPostingGroup(var Item: Record Item)
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
        BlankLocation: Record Location;
    begin
        CreateItem(Item);
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        BlankLocation.Init();
        LibraryInventory.UpdateInventoryPostingSetup(BlankLocation);
        Item.Validate("Inventory Posting Group", InventoryPostingGroup.Code);
        Item.Modify(true);
    end;

    local procedure CreatePurchaseOrderPostReceipt(var PurchaseLine: Record "Purchase Line"; Item: Record Item)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(2, 10));
        PurchaseLine.Validate("Direct Unit Cost", Item."Unit Cost");
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchaseLine.Find();
    end;

    local procedure CreateAndPostVendorInvoice(VendorNo: Code[20]; var DocumentNo: Code[20]; var Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        DocumentNo :=
          CreateAndPostPaymentJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Invoice, VendorNo, -LibraryRandom.RandDecInRange(1000, 2000, 2), '');
        Amount := -GenJournalLine.Amount;
    end;

    local procedure CreateAndPostVendorPayment(VendorNo: Code[20]; var DocumentNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        DocumentNo :=
          CreateAndPostPaymentJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Payment, VendorNo, Amount, '');
    end;

    local procedure FindDataRow(GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('AccNo', GenJournalLine."Account No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFound, 'AccNo', GenJournalLine."Account No.");
    end;

    local procedure PostPurchaseInvoiceOnDate(var PurchaseHeader: Record "Purchase Header"; NewPostingDate: Date)
    begin
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate("Posting Date", NewPostingDate);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure RunInventoryValue(ItemNoFilter: Text)
    begin
        LibraryVariableStorage.Enqueue(ItemNoFilter);  // Enqueue for InventoryValueRequestPageHandler.
        Commit();  // Commit required for InventoryValueRequestPageHandler.
        REPORT.Run(REPORT::"Inventory Value (Help Report)");
    end;

    local procedure RunGLSetupInformation(SetupInformation: Option)
    begin
        Commit();
        LibraryVariableStorage.Enqueue(SetupInformation);  // Enqueue for GLSetupInformationRequestPageHandler.
        REPORT.Run(REPORT::"G/L Setup Information");
    end;

    local procedure RunVendorPaymentsListReport(Sorting: Option; "Layout": Option; VendorNo: Code[20])
    begin
        Commit();
        LibraryVariableStorage.Enqueue(Sorting);  // Enqueue for VendorPaymentsListRequestPageHandler.
        LibraryVariableStorage.Enqueue(Layout);  // Enqueue for VendorPaymentsListRequestPageHandler.
        LibraryVariableStorage.Enqueue(VendorNo);  // Enqueue for VendorPaymentsListRequestPageHandler.
        REPORT.Run(REPORT::"Vendor Payments List");
    end;

    [Scope('OnPrem')]
    procedure SetApplyingVendorEntryForPayment(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, Amount);
    end;

    local procedure VerifyBankAccountPostingGroupOnGLSetupInformation()
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        LibraryReportDataset.SetRange('Bank_Posting_GroupsCaption', 'Bank Posting Groups');
        BankAccountPostingGroup.FindSet();
        repeat
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFound, 'Bank_Posting_GroupsCaption', 'Bank Posting Groups');
            LibraryReportDataset.AssertCurrentRowValueEquals('Bank_Account_Posting_Group_Code', BankAccountPostingGroup.Code);
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'Bank_Account_Posting_Group__G_L_Bank_Account_No__', BankAccountPostingGroup."G/L Account No.");
        until BankAccountPostingGroup.Next() = 0;
    end;

    local procedure VerifyCustomerPostingGroupOnGLSetupInformation()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibraryReportDataset.SetRange('Customer_Posting_GroupsCaption', 'Customer Posting Groups');
        CustomerPostingGroup.FindSet();
        repeat
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFound, 'Customer_Posting_GroupsCaption', 'Customer Posting Groups');
            LibraryReportDataset.AssertCurrentRowValueEquals('Customer_Posting_Group_Code', CustomerPostingGroup.Code);
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'Customer_Posting_Group__Receivables_Account_', CustomerPostingGroup."Receivables Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'Customer_Posting_Group__Service_Charge_Acc__', CustomerPostingGroup."Service Charge Acc.");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'Customer_Posting_Group__Invoice_Rounding_Account_', CustomerPostingGroup."Invoice Rounding Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'Customer_Posting_Group__Additional_Fee_Account_', CustomerPostingGroup."Additional Fee Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'Customer_Posting_Group__Interest_Account_', CustomerPostingGroup."Interest Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'Customer_Posting_Group__Debit_Curr__Appln__Rndg__Acc__', CustomerPostingGroup."Debit Curr. Appln. Rndg. Acc.");
        until CustomerPostingGroup.Next() = 0;
    end;

    local procedure VerifyGenBusinessPostingGroupOnGLSetupInformation()
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        LibraryReportDataset.SetRange('Gen__Business_Posting_GroupsCaption', 'Gen. Business Posting Groups');
        GenBusinessPostingGroup.FindSet();
        repeat
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFound, 'Gen__Business_Posting_GroupsCaption', 'Gen. Business Posting Groups');
            LibraryReportDataset.AssertCurrentRowValueEquals('Gen__Business_Posting_Group_Code', GenBusinessPostingGroup.Code);
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'Gen__Business_Posting_Group_Description', GenBusinessPostingGroup.Description);
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'Gen__Business_Posting_Group__Def__VAT_Bus__Posting_Group_', GenBusinessPostingGroup."Def. VAT Bus. Posting Group");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'Gen__Business_Posting_Group__Auto_Insert_Default_', GenBusinessPostingGroup."Auto Insert Default");
        until GenBusinessPostingGroup.Next() = 0;
    end;

    local procedure VerifyGeneralPostingSetupOnGLSetupInformation()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryReportDataset.SetRange('Gen__Posting_SetupCaption', 'Gen. Posting Setup');
        GeneralPostingSetup.FindSet();
        repeat
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFound, 'Gen__Posting_SetupCaption', 'Gen. Posting Setup');
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'General_Posting_Setup__Gen__Bus__Posting_Group_', GeneralPostingSetup."Gen. Bus. Posting Group");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'General_Posting_Setup__Gen__Prod__Posting_Group_', GeneralPostingSetup."Gen. Prod. Posting Group");
            LibraryReportDataset.AssertCurrentRowValueEquals('General_Posting_Setup__Sales_Account_', GeneralPostingSetup."Sales Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'General_Posting_Setup__Sales_Line_Disc__Account_', GeneralPostingSetup."Sales Line Disc. Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'General_Posting_Setup__Sales_Inv__Disc__Account_', GeneralPostingSetup."Sales Inv. Disc. Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'General_Posting_Setup__Sales_Pmt__Disc__Debit_Acc__', GeneralPostingSetup."Sales Pmt. Disc. Debit Acc.");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'General_Posting_Setup__Purch__Account_', GeneralPostingSetup."Purch. Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'General_Posting_Setup__Purch__Line_Disc__Account_', GeneralPostingSetup."Purch. Line Disc. Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'General_Posting_Setup__Purch__Inv__Disc__Account_', GeneralPostingSetup."Purch. Inv. Disc. Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'General_Posting_Setup__Purch__Pmt__Disc__Credit_Acc__', GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc.");
            LibraryReportDataset.AssertCurrentRowValueEquals('General_Posting_Setup__COGS_Account_', GeneralPostingSetup."COGS Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'General_Posting_Setup__Inventory_Adjmt__Account_', GeneralPostingSetup."Inventory Adjmt. Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'General_Posting_Setup__Sales_Credit_Memo_Account_', GeneralPostingSetup."Sales Credit Memo Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'General_Posting_Setup__Purch__Credit_Memo_Account_', GeneralPostingSetup."Purch. Credit Memo Account");
        until GeneralPostingSetup.Next() = 0;
    end;

    local procedure VerifyGenProductPostingGroupOnGLSetupInformation()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryReportDataset.SetRange('Gen__Product_Posting_GroupsCaption', 'Gen. Product Posting Groups');
        GenProductPostingGroup.FindSet();
        repeat
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFound, 'Gen__Product_Posting_GroupsCaption', 'Gen. Product Posting Groups');
            LibraryReportDataset.AssertCurrentRowValueEquals('Gen__Product_Posting_Group_Code', GenProductPostingGroup.Code);
            LibraryReportDataset.AssertCurrentRowValueEquals('Gen__Product_Posting_Group_Description', GenProductPostingGroup.Description);
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'Gen__Product_Posting_Group__Def__VAT_Prod__Posting_Group_', GenProductPostingGroup."Def. VAT Prod. Posting Group");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'Gen__Product_Posting_Group__Auto_Insert_Default_', GenProductPostingGroup."Auto Insert Default");
        until GenProductPostingGroup.Next() = 0;
    end;

    local procedure VerifyGLSetupCompanyDataConsolidation()
    var
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibraryReportDataset.LoadDataSetFile();
        CompanyInformation.Get();
        GeneralLedgerSetup.Get();
        LibraryReportDataset.SetRange('COMPANYNAME', CompanyInformation.Name);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFound, 'COMPANYNAME', CompanyInformation.Name);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__Appln__Rounding_Precision_', GeneralLedgerSetup."Appln. Rounding Precision");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__Amount_Rounding_Precision_', GeneralLedgerSetup."Amount Rounding Precision");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__LCY_Code_', GeneralLedgerSetup."LCY Code");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__VAT_Exchange_Rate_Adjustment_', Format(GeneralLedgerSetup."VAT Exchange Rate Adjustment"));
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__VAT_Tolerance___', GeneralLedgerSetup."VAT Tolerance %");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__EMU_Currency_', GeneralLedgerSetup."EMU Currency");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__Summarize_G_L_Entries_', GeneralLedgerSetup."Summarize G/L Entries");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__Bank_Account_Nos__', GeneralLedgerSetup."Bank Account Nos.");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__Local_Cont__Addr__Format_', Format(GeneralLedgerSetup."Local Cont. Addr. Format"));
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__Inv__Rounding_Precision__LCY__', GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__Inv__Rounding_Type__LCY__', Format(GeneralLedgerSetup."Inv. Rounding Type (LCY)"));
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__Local_Address_Format_', Format(GeneralLedgerSetup."Local Address Format"));
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__Mark_Cr__Memos_as_Corrections_', GeneralLedgerSetup."Mark Cr. Memos as Corrections");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__Adjust_for_Payment_Disc__', GeneralLedgerSetup."Adjust for Payment Disc.");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__Unrealized_VAT_', GeneralLedgerSetup."Unrealized VAT");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__Pmt__Disc__Excl__VAT_', GeneralLedgerSetup."Pmt. Disc. Excl. VAT");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__Max__VAT_Difference_Allowed_', GeneralLedgerSetup."Max. VAT Difference Allowed");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__VAT_Rounding_Type_', Format(GeneralLedgerSetup."VAT Rounding Type"));
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__Global_Dimension_1_Code_', GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'General_Ledger_Setup__Global_Dimension_2_Code_', GeneralLedgerSetup."Global Dimension 2 Code");

        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFound, 'COMPANYNAME', CompanyInformation.Name);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Company_Information__Ship_to_Post_Code_', CompanyInformation."Ship-to Post Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('Company_Information__Post_Code_', CompanyInformation."Post Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('Company_Information__Ship_to_Address_', CompanyInformation."Ship-to Address");
        LibraryReportDataset.AssertCurrentRowValueEquals('Company_Information__Ship_to_City_', CompanyInformation."Ship-to City");
        LibraryReportDataset.AssertCurrentRowValueEquals('Company_Information__Ship_to_Name_', CompanyInformation."Ship-to Name");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Company_Information__VAT_Registration_No__', CompanyInformation."VAT Registration No.");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Company_Information__Payment_Routing_No__', CompanyInformation."Payment Routing No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Company_Information__Bank_Account_No__', CompanyInformation."Bank Account No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Company_Information__Bank_Branch_No__', CompanyInformation."Bank Branch No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Company_Information__Giro_No__', CompanyInformation."Giro No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Company_Information__Bank_Name_', CompanyInformation."Bank Name");
        LibraryReportDataset.AssertCurrentRowValueEquals('Company_Information__Fax_No__', CompanyInformation."Fax No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Company_Information_City', CompanyInformation.City);
        LibraryReportDataset.AssertCurrentRowValueEquals('Company_Information__Phone_No__', CompanyInformation."Phone No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Company_Information_Address', CompanyInformation.Address);
    end;

    local procedure VerifyInventoryPostingGroupOnGLSetupInformation()
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        LibraryReportDataset.SetRange('Inventory_Posting_GroupsCaption', 'Inventory Posting Groups');
        InventoryPostingGroup.FindSet();
        repeat
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFound, 'Inventory_Posting_GroupsCaption', 'Inventory Posting Groups');
            LibraryReportDataset.AssertCurrentRowValueEquals('Inventory_Posting_Group_Code', InventoryPostingGroup.Code);
        until InventoryPostingGroup.Next() = 0;
    end;

    local procedure VerifyInventoryValue(ItemNo: Code[20]; Quantity: Decimal; InvoicedQuantity: Decimal; ExpectedAmount: Decimal; ActualAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        VerifyItemInventoryCost(ItemNo, Quantity, InvoicedQuantity, ExpectedAmount, ActualAmount);
    end;

    local procedure VerifyInventoryValueAndPostingGroup(ItemJournalLine: Record "Item Journal Line"; Quantity: Decimal; InvoicedQuantity: Decimal; ExpectedAmount: Decimal; ActualAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        VerifyItemInventoryCost(ItemJournalLine."Item No.", Quantity, InvoicedQuantity, ExpectedAmount, ActualAmount);
        VerifyInventoryReportForPostingGroup(ItemJournalLine."Inventory Posting Group", ExpectedAmount, ActualAmount);
    end;

    local procedure VerifyInventoryValueWithDiffrentPostingGroup(FirstItemInventoryPostingGroupCode: Code[20]; SecondItemInventoryPostingGroupCode: Code[20]; FirstItemActualAmount: Decimal; FirstItemExpectedAmount: Decimal; SecondItemActualAmount: Decimal; SecondItemExpectedAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        VerifyInventoryReportForPostingGroup(FirstItemInventoryPostingGroupCode, FirstItemExpectedAmount, FirstItemActualAmount);
        VerifyInventoryReportForPostingGroup(SecondItemInventoryPostingGroupCode, SecondItemExpectedAmount, SecondItemActualAmount);
    end;

    local procedure VerifyItemABCAnalysis(ItemJournalLine: Record "Item Journal Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', ItemJournalLine."Item No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFound, 'No_Item', ItemJournalLine."Item No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('InvntPostingGroup_Item', ItemJournalLine."Inventory Posting Group");
        LibraryReportDataset.AssertCurrentRowValueEquals('ABC', 'A');  // Value required for test.
        LibraryReportDataset.AssertCurrentRowValueEquals('Pct', 100);  // Value required for test.
        LibraryReportDataset.AssertCurrentRowValueEquals('Col1Value', ItemJournalLine.Quantity);
    end;

    local procedure VerifyItemInventoryCost(ItemNo: Code[20]; Quantity: Decimal; InvoicedQuantity: Decimal; ExpectedAmount: Decimal; ActualAmount: Decimal)
    begin
        LibraryReportDataset.SetRange('ItemNo', ItemNo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFound, 'ItemNo', ItemNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemNetChange', Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('InvoicedQuantity', InvoicedQuantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('CostAmountTotal', ExpectedAmount + ActualAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('CostAmountExpected', ExpectedAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('CostAmountActual', ActualAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('CostPostedtoGL', ActualAmount);
    end;

    local procedure VerifyProvisionalTrialBalance(GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('G_L_Account___No__', GenJournalLine."Account No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFound, 'G_L_Account___No__', GenJournalLine."Account No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('ProvBalance', -GenJournalLine.Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('ProvAmt', GenJournalLine.Amount);
    end;

    local procedure VerifyInventoryReportForPostingGroup(InventoryPostingGroupCode: Code[20]; ExpectedAmount: Decimal; ActualAmount: Decimal)
    begin
        LibraryReportDataset.SetRange('PostingGroupCode', InventoryPostingGroupCode);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFound, 'PostingGroupCode', InventoryPostingGroupCode);
        LibraryReportDataset.AssertCurrentRowValueEquals('PostingGroupInvValuationActual', ActualAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('PostingGroupInvValuationExp', ExpectedAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('PostingGroupInvPostedtoGL', ActualAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('PostingGroupInvValuationTotal', ExpectedAmount + ActualAmount);
    end;

    local procedure VerifySourceCodeOnGLSetupInformation()
    var
        SourceCode: Record "Source Code";
    begin
        LibraryReportDataset.SetRange('SourceCaption', 'Source');
        SourceCode.FindSet();
        repeat
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFound, 'SourceCaption', 'Source');
            LibraryReportDataset.AssertCurrentRowValueEquals('Source_Code_Code', SourceCode.Code);
            LibraryReportDataset.AssertCurrentRowValueEquals('Source_Code_Description', SourceCode.Description);
        until SourceCode.Next() = 0;
    end;

    local procedure VerifySourceCodeSetupOnGLSetupInformation()
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        LibraryReportDataset.SetRange('Source_SetupCaption', 'Source Setup');
        SourceCodeSetup.Get();
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFound, 'Source_SetupCaption', 'Source Setup');
        LibraryReportDataset.AssertCurrentRowValueEquals('Source_Code_Setup__General_Journal_', SourceCodeSetup."General Journal");
        LibraryReportDataset.AssertCurrentRowValueEquals('Source_Code_Setup_Sales', SourceCodeSetup.Sales);
        LibraryReportDataset.AssertCurrentRowValueEquals('Source_Code_Setup_Purchases', SourceCodeSetup.Purchases);
        LibraryReportDataset.AssertCurrentRowValueEquals('Source_Code_Setup__Item_Journal_', SourceCodeSetup."Item Journal");
        LibraryReportDataset.AssertCurrentRowValueEquals('Source_Code_Setup__Resource_Journal_', SourceCodeSetup."Resource Journal");
        LibraryReportDataset.AssertCurrentRowValueEquals('Source_Code_Setup__Job_Journal_', SourceCodeSetup."Job Journal");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Source_Code_Setup__Fixed_Asset_Journal_', SourceCodeSetup."Fixed Asset Journal");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Source_Code_Setup__Item_Reclass__Journal_', SourceCodeSetup."Item Reclass. Journal");
    end;

    local procedure VerifyVATBusinessPostingGroupOnGLSetupInformation()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryReportDataset.SetRange('VAT_Posting_GroupsCaption', 'VAT Posting Groups');
        VATBusinessPostingGroup.FindSet();
        repeat
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFound, 'VAT_Posting_GroupsCaption', 'VAT Posting Groups');
            LibraryReportDataset.AssertCurrentRowValueEquals('VAT_Business_Posting_Group_Code', VATBusinessPostingGroup.Code);
            LibraryReportDataset.AssertCurrentRowValueEquals('VAT_Business_Posting_Group_Description', VATBusinessPostingGroup.Description);
        until VATBusinessPostingGroup.Next() = 0;
    end;

    local procedure VerifyVATProductPostingGroupOnGLSetupInformation()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryReportDataset.SetRange('VAT_Product_Posting_GroupsCaption', 'VAT Product Posting Groups');
        VATProductPostingGroup.FindSet();
        repeat
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFound, 'VAT_Product_Posting_GroupsCaption', 'VAT Product Posting Groups');
            LibraryReportDataset.AssertCurrentRowValueEquals('VAT_Product_Posting_Group_Code', VATProductPostingGroup.Code);
            LibraryReportDataset.AssertCurrentRowValueEquals('VAT_Product_Posting_Group_Description', VATProductPostingGroup.Description);
        until VATProductPostingGroup.Next() = 0;
    end;

    local procedure VerifyVATPostingSetupOnGLSetupInformation()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryReportDataset.SetRange('VAT_SetupCaption', 'VAT Setup');
        VATPostingSetup.FindSet();
        repeat
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFound, 'VAT_SetupCaption', 'VAT Setup');
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VAT_Posting_Setup__VAT_Bus__Posting_Group_', VATPostingSetup."VAT Bus. Posting Group");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VAT_Posting_Setup__VAT_Prod__Posting_Group_', VATPostingSetup."VAT Prod. Posting Group");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VAT_Posting_Setup__VAT_Calculation_Type_', Format(VATPostingSetup."VAT Calculation Type"));
            LibraryReportDataset.AssertCurrentRowValueEquals('VAT_Posting_Setup__VAT___', VATPostingSetup."VAT %");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VAT_Posting_Setup__Adjust_for_Payment_Discount_', VATPostingSetup."Adjust for Payment Discount");
            LibraryReportDataset.AssertCurrentRowValueEquals('VAT_Posting_Setup__Sales_VAT_Account_', VATPostingSetup."Sales VAT Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VAT_Posting_Setup__Sales_VAT_Unreal__Account_', VATPostingSetup."Sales VAT Unreal. Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VAT_Posting_Setup__Purchase_VAT_Account_', VATPostingSetup."Purchase VAT Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VAT_Posting_Setup__Purch__VAT_Unreal__Account_', VATPostingSetup."Purch. VAT Unreal. Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VAT_Posting_Setup__Reverse_Chrg__VAT_Acc__', VATPostingSetup."Reverse Chrg. VAT Acc.");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'VAT_Posting_Setup__Reverse_Chrg__VAT_Unreal__Acc__', VATPostingSetup."Reverse Chrg. VAT Unreal. Acc.");
        until VATPostingSetup.Next() = 0;
    end;

    local procedure VerifyVendorPaymentListReportWithStandardLayout(GenJournalLine: Record "Gen. Journal Line")
    begin
        FindDataRow(GenJournalLine);
        LibraryReportDataset.AssertCurrentRowValueEquals('PaymentLCY', GenJournalLine.Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('Vendor_Ledger_Entry__Amount__LCY__', GenJournalLine.Amount);
    end;

    local procedure VerifyVendorPaymentListReportWithFCYAmountLayout(GenJournalLine: Record "Gen. Journal Line"; CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
        FindDataRow(GenJournalLine);
        LibraryReportDataset.AssertCurrentRowValueEquals('Vendor_Ledger_Entry__Original_Amount_', GenJournalLine.Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Vendor_Ledger_Entry__Amount__LCY__',
          Round(
            GenJournalLine.Amount * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount",
            0.01));  // Calculated Values required for test.
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Exrate',
          Round(
            GenJournalLine."Amount (LCY)" * CurrencyExchangeRate."Relational Exch. Rate Amount" / GenJournalLine.Amount,
            0.001));  // Calculated Values required for test.
        LibraryReportDataset.AssertCurrentRowValueEquals('Status', 'Open');
    end;

    local procedure VerifyVendorPaymentListReportWithApplicationEntry(GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('AccNo', GenJournalLine."Account No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFound, 'AccNo', GenJournalLine."Account No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('TempVendorLedgerEntry__Document_No__', GenJournalLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('PaymentLCY', -GenJournalLine.Amount);
    end;

    local procedure VerifyAppliestoDocNoOnVendorPaymentList(DocumentNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TempVendorLedgerEntry__Document_No__', DocumentNo);
    end;

    local procedure VerifyTotalAmtOnVendorPaymentList(TotalAmountLCY: Decimal; TotalDiscLCY: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Total_Payment_LCY', -TotalAmountLCY);
        LibraryReportDataset.AssertElementWithValueExists('Total_Amount_LCY', -(TotalAmountLCY + TotalDiscLCY));
        LibraryReportDataset.AssertElementWithValueExists('Total_Pmt_Disc_LCY', -TotalDiscLCY);
    end;

    local procedure VerifyVendorPostingGroupOnGLSetupInformation()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LibraryReportDataset.SetRange('Vendor_Posting_GroupsCaption', 'Vendor Posting Groups');
        VendorPostingGroup.FindSet();
        repeat
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFound, 'Vendor_Posting_GroupsCaption', 'Vendor Posting Groups');
            LibraryReportDataset.AssertCurrentRowValueEquals('Vendor_Posting_Group_Code', VendorPostingGroup.Code);
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'Vendor_Posting_Group__Payables_Account_', VendorPostingGroup."Payables Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'Vendor_Posting_Group__Service_Charge_Acc__', VendorPostingGroup."Service Charge Acc.");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'Vendor_Posting_Group__Invoice_Rounding_Account_', VendorPostingGroup."Invoice Rounding Account");
            LibraryReportDataset.AssertCurrentRowValueEquals(
              'Vendor_Posting_Group__Debit_Curr__Appln__Rndg__Acc__', VendorPostingGroup."Debit Curr. Appln. Rndg. Acc.");
        until VendorPostingGroup.Next() = 0;
    end;

    local procedure VerifyVendorLedgerEntryAmount(Row: Integer; Amount: Decimal)
    begin
        LibraryReportDataset.MoveToRow(Row);
        LibraryReportDataset.AssertCurrentRowValueEquals('Vendor_Ledger_Entry__Amount__LCY__', Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('Vendor_Ledger_Entry__Amount__LCY___Control56', Amount);
    end;

    local procedure CreateVendorWithPmtTerms(): Code[20]
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);
        exit(Vendor."No.")
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLSetupInformationRequestPageHandler(var GLSetupInformation: TestRequestPage "G/L Setup Information")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        GLSetupInformation.SetupInformation.SetValue(DequeueVariable);
        GLSetupInformation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryValueRequestPageHandler(var InventoryValue: TestRequestPage "Inventory Value (Help Report)")
    begin
        InventoryValue.Item.SetFilter("No.", LibraryVariableStorage.DequeueText());
        InventoryValue.StatusDate.SetValue(WorkDate());
        InventoryValue.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemABCAnalysisRequestPageHandler(var ItemABCAnalysis: TestRequestPage "Item ABC Analysis")
    var
        ItemNo: Variant;
    begin
        ItemABCAnalysis.ValueInColumn1.SetValue(ItemABCAnalysis.ValueInColumn1.GetOption(1));  // Use 1 for Stock.
        ItemABCAnalysis.RatioCatA.SetValue(LibraryRandom.RandInt(100));  // Value required for test.
        ItemABCAnalysis.ShowCategoryA.SetValue(true);
        LibraryVariableStorage.Dequeue(ItemNo);
        ItemABCAnalysis.Item.SetFilter("No.", ItemNo);
        ItemABCAnalysis.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProvisionalTrialBalanceRequestPageHandler(var ProvisionalTrialBalance: TestRequestPage "Provisional Trial Balance")
    var
        JournalBatch: Variant;
        GLAccountNo: Variant;
    begin
        ProvisionalTrialBalance.BalanceToDate.SetValue(WorkDate());
        LibraryVariableStorage.Dequeue(JournalBatch);
        ProvisionalTrialBalance.WithJournal1.SetValue(JournalBatch);
        LibraryVariableStorage.Dequeue(GLAccountNo);
        ProvisionalTrialBalance."G/L Account".SetFilter("No.", GLAccountNo);
        ProvisionalTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorPaymentsListRequestPageHandler(var VendorPaymentsList: TestRequestPage "Vendor Payments List")
    var
        Sorting: Variant;
        "Layout": Variant;
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(Sorting);
        LibraryVariableStorage.Dequeue(Layout);
        LibraryVariableStorage.Dequeue(VendorNo);
        VendorPaymentsList.Sorting.SetValue(Sorting);
        VendorPaymentsList.Layout.SetValue(Layout);
        VendorPaymentsList."Vendor Ledger Entry".SetFilter("Vendor No.", VendorNo);
        VendorPaymentsList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ValueEntriesWerePostedTxt, Message);
    end;
}

