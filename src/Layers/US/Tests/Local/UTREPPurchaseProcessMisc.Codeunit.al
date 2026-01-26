codeunit 144004 "UT REP Purchase Process Misc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Reports]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        SubTitleCap: Label 'SubTitle';
        VendTotalLabelCap: Label 'VendTotalLabel';
        ErrorTextNumberCap: Label 'ErrorText_Number_';
        GenJournalLineAmountCap: Label 'Gen__Journal_Line_Amount';
        TitleCap: Label 'Subtitle';
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;
        DefaultTxt: Label 'LCY';
        AmountDue2: label 'AmountDue_2_';
        AmountDue3: label 'AmountDue_3_';

    [Test]
    [HandlerFunctions('ReconcileAPToGLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemReconcileAPToGL()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Purpose of the test is to validate Integer - OnPreDataItem trigger of the Report ID: 10101, Reconcile AP to GL for Subtitle.
        // Setup.
        Initialize();
        CreatePurchaseOrder(PurchaseLine, '');

        // Exercise.
        RunReconcileAPToGLReport(PurchaseLine."Document No.");

        // Verify: Verify the Subtitle after running Reconcile AP to GL Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Subtitle', '(Accruals)');
    end;

    [Test]
    [HandlerFunctions('BankAccountCheckDetailsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecChkLedgEntryPrintedBankAccChkDetails()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger Check Ledger Entry of Report 1406 - Bank Account - Check Details.

        // Setup: Create Check Ledger Entry With Entry Status - Printed.
        Initialize();
        OnAfterGetRecChkLedgEntryBankAccountCheckDetails('AmountPrinted', CheckLedgerEntry."Entry Status"::Printed);
    end;

    [Test]
    [HandlerFunctions('BankAccountCheckDetailsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecChkLedgEntryVoidedBankAccChkDetails()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger Check Ledger Entry of Report 1406 - Bank Account - Check Details.

        // Setup: Create Check Ledger Entry With Entry Status - Voided.
        Initialize();
        OnAfterGetRecChkLedgEntryBankAccountCheckDetails('AmountVoided', CheckLedgerEntry."Entry Status"::Voided);
    end;

    local procedure OnAfterGetRecChkLedgEntryBankAccountCheckDetails(ElementNameCaption: Text; EntryStatus: Option)
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        // Create Check Legder Entry with Entry Status.
        CreateCheckLedgerEntry(CheckLedgerEntry, EntryStatus);

        // Exercise.
        LibraryLowerPermissions.SetBanking();
        REPORT.Run(REPORT::"Bank Account - Check Details");  // Opens handler - BankAccountCheckDetailsRequestPageHandler.

        // Verify: Verify Amount on Report Bank Account - Check Details.
        VerifyReportsPP(ElementNameCaption, CheckLedgerEntry.Amount)
    end;

    [Test]
    [HandlerFunctions('ProjectedCashPaymentsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCurrencyWithoutPrintProjCashPayments()
    var
        Vendor: Record Vendor;
        GeneralLedgerSetup: Record "General Ledger Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test to verify the VendCurrency - OnAfterGetRecord trigger of the Report ID: 10098, Projected Cash Payments Report without Print Totals.
        // Setup.
        Initialize();
        CreateVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", '');  // Blank Purchaser Code.

        // Exercise.
        RunProjectedCashPaymentsReport(Vendor."No.", false);  // FALSE for Print Totals in Vendor Currency.

        // Verify: Verify the Vendor Total Label after running Projected Cash Payments Report.
        GeneralLedgerSetup.Get();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          VendTotalLabelCap, 'Total for ' + Vendor.TableCaption + ' ' + Vendor."No." + ' (' + GeneralLedgerSetup."LCY Code" + ')');
    end;

    [Test]
    [HandlerFunctions('ProjectedCashPaymentsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCurrencyWithPrintProjCashPayments()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test to verify the VendCurrency - OnAfterGetRecord trigger of the Report ID: 10098, Projected Cash Payments Report with Print Totals.
        // Setup.
        Initialize();
        CreateVendor(Vendor);
        UpdateCurrencyCodeOnVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", '');  // Blank Purchaser Code.

        // Exercise.
        RunProjectedCashPaymentsReport(Vendor."No.", true);  // TRUE for Print Totals in Vendor Currency.

        // Verify: Verify the Vendor Total Label after running Projected Cash Payments Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          VendTotalLabelCap, 'Total for ' + Vendor.TableCaption + ' ' + Vendor."No." + ' (' + Vendor."Currency Code" + ')');
    end;

    [Test]
    [HandlerFunctions('ProjectedCashPaymentsWithStartDateRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ProjectedCashPaymentsOnAfterGetRecordAmountDueCleaned()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ProjectedCashPayments: Report "Projected Cash Payments";
    begin
        // [SCENARIO] Test to verify the that global value AmountDue was being cleared after each line.

        // [GIVEN] Vendor
        Initialize();
        CreateVendor(Vendor);
        // [GIVEN] Creating 2 Vendor Ledger Entries or the specified Vendor
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", '');
        VendorLedgerEntry.Validate(Amount, -1000);
        VendorLedgerEntry.Modify(true);
        // [GIVEN] Difference between Posting Date and Due Date for created Ledger Entries is more than month but less then 2 months
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", '');
        VendorLedgerEntry.Validate("Posting Date", LibraryRandom.RandDateFromInRange(WorkDate(), 40, 60));
        VendorLedgerEntry.Validate("Due Date", VendorLedgerEntry."Posting Date");
        VendorLedgerEntry.Validate(Amount, -2000);
        VendorLedgerEntry.Modify(true);

        // [WHEN] Running ProjectedCashPayments Report for the specified Vendor
        // [WHEN] BeginProjectionDate is setted as the Due Date of the first Ledger Entry
        LibraryVariableStorage.Enqueue(WorkDate());
        ProjectedCashPayments.SetTableView(Vendor);
        LibraryLowerPermissions.SetAccountPayables();
        ProjectedCashPayments.Run(); // Invokes ProjectedCashPaymentsWithStartDateRequestPageHandler.

        // [THEN] For each month only 1 AmountDue have to be specified
        LibraryReportDataset.LoadDataSetFile();
        // [THEN] Only AmountDue2 should be presented for the first month
        LibraryReportDataset.AssertElementWithValueExists(AmountDue2, 1000);
        LibraryReportDataset.AssertElementWithValueExists(AmountDue3, 0);
        // [THEN] Only AmountDue3 should be presented for the second month
        LibraryReportDataset.AssertElementWithValueExists(AmountDue2, 0);
        LibraryReportDataset.AssertElementWithValueExists(AmountDue3, 2000);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PaymentJournalTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineCheckExportPaymentJnlTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify the Gen. Journal Line - OnAfterGetRecord trigger of the Report ID: 10089, Payment Journal - Test Report for Bank Payment Type of Electronic Payment for Check Exported.
        // Setup.
        Initialize();
        CreateAndUpdateGenJournalLine(
          GenJournalLine, CreateBankAccount(), GenJournalLine."Bank Payment Type"::"Electronic Payment", LibraryRandom.RandDec(10, 2));
        UpdateBalanceAccountOnGenJournalLine(GenJournalLine);

        // Exercise.
        RunPaymentJournalTestReport(GenJournalLine."Account No.");

        // Verify: Verify the Error Text Number and Amount after running Payment Journal Test Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ErrorTextNumberCap, 'Check Exported must be Yes for a(n) Electronic Payment.');
        LibraryReportDataset.AssertElementWithValueExists(GenJournalLineAmountCap, GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('PaymentJournalTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineCheckTransmitPaymentJnlTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify the Gen. Journal Line - OnAfterGetRecord trigger of the Report ID: 10089, Payment Journal - Test Report for Bank Payment Type of Electronic Payment for Check Transmitted.
        // Setup.
        Initialize();
        CreateAndUpdateGenJournalLine(
          GenJournalLine, CreateBankAccount(), GenJournalLine."Bank Payment Type"::"Electronic Payment", LibraryRandom.RandDec(10, 2));

        // Exercise.
        RunPaymentJournalTestReport(GenJournalLine."Account No.");

        // Verify: Verify the Error Text Number and Amount after running Payment Journal Test Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          ErrorTextNumberCap, 'Check Transmitted must be Yes for a(n) Electronic Payment.');
        LibraryReportDataset.AssertElementWithValueExists(GenJournalLineAmountCap, GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('PaymentJournalTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLinePrintCheckPaymtJnlTest()
    begin
        // Test to verify the Gen. Journal Line - OnAfterGetRecord trigger of the Report ID: 10089, Payment Journal - Test Report for Bank Payment Type of Computer Check for Check Printed with positive Amount.
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLinePrintCheckPaymentJnlTest(LibraryRandom.RandDec(10, 2));  // Amount Positive.
    end;

    [Test]
    [HandlerFunctions('PaymentJournalTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLinePrintCheckNegPaymentJnlTest()
    begin
        // Test to verify the Gen. Journal Line - OnAfterGetRecord trigger of the Report ID: 10089, Payment Journal - Test Report for Bank Payment Type of Computer Check for Check Printed with Negative Amount.
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLinePrintCheckPaymentJnlTest(-LibraryRandom.RandDec(10, 2));  // Amount Negative.
    end;

    local procedure OnAfterGetRecordGenJnlLinePrintCheckPaymentJnlTest(Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndUpdateGenJournalLine(GenJournalLine, CreateBankAccount(), GenJournalLine."Bank Payment Type"::"Computer Check", Amount);

        // Exercise.
        RunPaymentJournalTestReport(GenJournalLine."Account No.");

        // Verify: Verify the Error Text Number and Amount after running Payment Journal Test Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ErrorTextNumberCap, 'Posting Date must be specified.');
        LibraryReportDataset.AssertElementWithValueExists(GenJournalLineAmountCap, GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('OutstandingPurchOrderStatusRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchLineOutstandingPurchOrderStatus()
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
    begin
        // Test to verify the Purchase Line - OnAfterGetRecord trigger of Report ID: 10096, Outstanding Purch.Order Status Report for Purchase order created.
        // Setup.
        Initialize();
        CreateVendor(Vendor);
        CreatePurchaseOrder(PurchaseLine, Vendor."No.");

        // Exercise.
        RunOutstandingPurchOrderStatusReport(Vendor."No.");

        // Verify: Verify the Purchase Line Quantity and Outstanding Quantity after running Outstanding Purch. Order Status Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Purchase_Line_Quantity', PurchaseLine.Quantity);
        LibraryReportDataset.AssertElementWithValueExists('Purchase_Line__Outstanding_Quantity_', PurchaseLine."Outstanding Quantity");
    end;

    [Test]
    [HandlerFunctions('OutstandingPurchOrderAgingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorPrintOutstandingPurchOrderAging()
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
    begin
        // Test to verify the Vendor - OnAfterGetRecord trigger of Report ID: 10095, Outstanding Purch. Order Aging Report for Vendor Subtitle with Print Detail.
        // Setup.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        CreateVendor(Vendor);
        CreatePurchaseOrder(PurchaseLine, Vendor."No.");

        // Exercise.
        RunOutstandingPurchOrderAgingReport(Vendor."No.", true);  // TRUE for Print Detail.

        // Verify: Verify the Subtitle after running Outstanding Purch. Order Aging Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TitleCap, '(Detail)');
    end;

    [Test]
    [HandlerFunctions('OutstandingPurchOrderAgingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorOutstandingPurchOrderAging()
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
    begin
        // Test to verify the Vendor - OnAfterGetRecord trigger of Report ID: 10095, Outstanding Purch. Order Aging Report for Vendor Subtitle without Print Detail.
        // Setup.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        CreateVendor(Vendor);
        CreatePurchaseOrder(PurchaseLine, Vendor."No.");

        // Exercise.
        RunOutstandingPurchOrderAgingReport(Vendor."No.", false);  // FALSE for Print Detail.

        // Verify: Verify the Subtitle after running Outstanding Purch. Order Aging Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TitleCap, '(Summary)');
    end;

    [Test]
    [HandlerFunctions('CashRequirementsByDueDateRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVendLedgerEntryCashReqByDueDate()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test to verify the Vendor Ledger Entry - OnPreDataItem trigger of Report ID: 10088, Cash Requirements by Due Date Report for Subtitle without Print Detail.
        // Setup.
        Initialize();
        CreateVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", '');  // Blank Purchaser Code.

        // Exercise.
        RunCashRequirementsByDueDateReport(Vendor."No.", false);  // FALSE for Print Detail.

        // Verify: Verify the Subtitle after running Cash Requirements By Due Date Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          TitleCap, '(' + 'Summary for payments as of' + ' ' + Format(WorkDate(), 0, 4) + ')');
    end;

    [Test]
    [HandlerFunctions('CashRequirementsByDueDateRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVendLedgerEntryPrintCashReqByDueDate()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test to verify the Vendor Ledger Entry - OnPreDataItem trigger of Report ID: 10088, Cash Requirements by Due Date Report for Subtitle with Print Detail.
        // Setup.
        Initialize();
        CreateVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", '');  // Blank Purchaser Code.

        // Exercise.
        RunCashRequirementsByDueDateReport(Vendor."No.", true);  // TRUE for Print Detail.

        // Verify: Verify the Subtitle after running Cash Requirements By Due Date Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TitleCap, '(' + 'Detail for payments as of' + ' ' + Format(WorkDate(), 0, 4) + ')');
    end;

    [Test]
    [HandlerFunctions('CashApplicationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorCashApplication()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Test to verify the Vendor - OnAfterGetRecord trigger of Report ID: 10086, Cash Application Report for Payment Date.
        // Setup.
        Initialize();
        CreateVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", '');  // Blank Purchaser Code.

        // Exercise.
        RunCashApplicationReport(Vendor."No.");

        // Verify: Verify the Payment date String after running Cash Application Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('PaymentDateString', '(For Payment on ' + Format(WorkDate(), 0, 4) + ')');
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSuggestVendorPayments()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord trigger of the Report ID: 393, Suggest Vendor Payments.
        // Setup.
        Initialize();
        CreateVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", '');  // Blank Purchaser Code.
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", VendorLedgerEntry."Vendor No.");

        // Exercise.
        RunSuggestVendorPaymentsReport(Vendor."No.");

        // Verify: Verify that Accepted Payment Tolerance is zero after running Suggest Vendor Payments.
        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.TestField("Accepted Payment Tolerance", 0);
    end;

    [Test]
    [HandlerFunctions('ItemStatisticsByPurchaserRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemStatisticsByPurchaser()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        // Purpose of the test is to validate Value Entry - OnPreDataItem trigger of the Report ID: 10091, Item Statistics by Purchaser.
        // Setup.
        Initialize();
        CreateSalespersonPurchaser(SalespersonPurchaser);
        CreateValueEntry(SalespersonPurchaser.Code);

        // Exercise.
        RunItemStatisticsByPurchaserReport(SalespersonPurchaser.Code);

        // Verify: Verify the Item Description and Average Cost as Zero after running Item Statistics by Purchaser Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Item_Description', 'Others');
        LibraryReportDataset.AssertElementWithValueExists('AverageCost', 0);  // Average Cost Zero.
    end;

    [Test]
    [HandlerFunctions('OutstandingOrderStatByPORequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportOutstandingOrderStatByPO()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Purpose of the test is to validate OnPreReport trigger of the Report ID: 10094, Outstanding Order Stat. by PO.
        // Setup.
        Initialize();
        CreatePurchaseOrder(PurchaseLine, '');  // Blank Buy from Vendor No.

        // Exercise.
        RunOutstandingOrderStatByPOReport(PurchaseLine."Document No.");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'Control33Caption', ResolveCaption('Report Total (%1)'));  // Calculate Control33Caption as calculated in the Report.
    end;

    [Test]
    [HandlerFunctions('PurchaserInvoiceByStatRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemPurchaserStatByInvoiceWithoutPrintDetail()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate Salesperson/Purchaser - OnPreDataItem trigger of the REPORT ID: 10100, Purchaser Stat. by Invoice for SubTitle without Print Detail.
        // Setup.
        Initialize();
        CreateSalespersonPurchaser(SalespersonPurchaser);
        CreateVendorLedgerEntry(VendorLedgerEntry, '', SalespersonPurchaser.Code);  // Blank Vendor No.

        // Exercise.
        RunPurchaserStatByInvoiceReport(VendorLedgerEntry."Purchaser Code", false);  // FALSE for Print Detail.

        // Verify: Verify the SubTitle after running Purchaser Stat. by Invoice Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SubTitleCap, '(Summary)');
    end;

    [Test]
    [HandlerFunctions('PurchaserInvoiceByStatRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemPurchaserStatByInvoiceWithPrintDetail()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate Salesperson/Purchaser - OnPreDataItem trigger of the REPORT ID: 10100, Purchaser Stat. by Invoice for SubTitle with Print Detail.
        // Setup.
        Initialize();
        CreateSalespersonPurchaser(SalespersonPurchaser);
        CreateVendorLedgerEntry(VendorLedgerEntry, '', SalespersonPurchaser.Code);  // Blank Vendor No.

        // Exercise.
        RunPurchaserStatByInvoiceReport(VendorLedgerEntry."Purchaser Code", true);  // TRUE for Print Detail.

        // Verify: Verify the SubTitle after running Purchaser Stat. by Invoice Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SubTitleCap, '(Detail)');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryLowerPermissions.SetOutsideO365Scope();

        if not IsInitialized then begin
            LibraryApplicationArea.EnableFoundationSetup();
            IsInitialized := true;
        end;
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Name := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; BuyFromVendorNo: Code[20])
    begin
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        PurchaseLine."Document No." := CreatePurchaseHeader();
        PurchaseLine."Line No." := 1;
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."Amt. Rcd. Not Invoiced" := LibraryRandom.RandDec(10, 2);
        PurchaseLine."Buy-from Vendor No." := BuyFromVendorNo;
        PurchaseLine."Expected Receipt Date" := WorkDate();
        PurchaseLine."Outstanding Quantity" := LibraryRandom.RandDec(10, 2);
        PurchaseLine.Quantity := LibraryRandom.RandDec(10, 2);
        PurchaseLine.Insert();
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; PurchaserCode: Code[20])
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry2.FindLast();
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Due Date" := WorkDate();
        VendorLedgerEntry."Pmt. Discount Date" := WorkDate();
        VendorLedgerEntry."Purchase (LCY)" := LibraryRandom.RandDec(10, 2);
        VendorLedgerEntry."Accepted Payment Tolerance" := LibraryRandom.RandDec(10, 2);
        VendorLedgerEntry."Original Pmt. Disc. Possible" := -LibraryRandom.RandDec(10, 2);
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Purchaser Code" := PurchaserCode;
        VendorLedgerEntry.Insert();
    end;

    local procedure CreateDetailedVendorLedgerEntry(VendorLedgerEntryNo: Integer; VendorNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry2.FindLast();
        DetailedVendorLedgEntry."Entry No." := DetailedVendorLedgEntry2."Entry No." + 1;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntryNo;
        DetailedVendorLedgEntry."Vendor No." := VendorNo;
        DetailedVendorLedgEntry.Amount := LibraryRandom.RandDec(10, 2);
        DetailedVendorLedgEntry."Amount (LCY)" := -DetailedVendorLedgEntry.Amount;
        DetailedVendorLedgEntry.Insert(true);
        LibraryVariableStorage.Enqueue(DetailedVendorLedgEntry."Vendor No.");  // Enqueue value required in PrintDetailAgedAccountsPayableRequestPageHandler.
    end;

    local procedure CreatePurchaseHeader(): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor);
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Buy-from Vendor No." := Vendor."No.";
        PurchaseHeader.Insert();
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");  // Enqueue value required in PurchaseDocumentTestRequestPageHandler.
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateCheckLedgerEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; EntryStatus: Option)
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.FindFirst();
        BankAccount.SetRange("Date Filter", WorkDate());
        CheckLedgerEntry."Entry No." := SelectCheckLedgerEntryNo();
        CheckLedgerEntry."Bank Account No." := BankAccount."No.";
        CheckLedgerEntry.Amount := LibraryRandom.RandDec(10, 2);
        CheckLedgerEntry."Check Date" := BankAccount."Date Filter";
        CheckLedgerEntry."Entry Status" := EntryStatus;
        CheckLedgerEntry.Insert();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateGenJournalLineWithAppliesToDocType(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type")
    begin
        CreateGenJournalLine(GenJournalLine, AccountType, AccountNo, LibraryRandom.RandDec(10, 2));
        GenJournalLine."Applies-to Doc. Type" := AppliesToDocType;
        GenJournalLine.Modify();
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; GenJnlLineAmount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate.Insert();
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        GenJournalBatch.Insert();

        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Line No." := 1;
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        GenJournalLine.Amount := GenJnlLineAmount;
        GenJournalLine."Amount (LCY)" := GenJnlLineAmount;
        GenJournalLine."Balance (LCY)" := GenJournalLine."Amount (LCY)";
        GenJournalLine.Insert();
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Insert();
        CurrencyExchangeRate."Currency Code" := Currency.Code;
        CurrencyExchangeRate."Starting Date" := WorkDate();
        CurrencyExchangeRate."Exchange Rate Amount" := LibraryRandom.RandDec(10, 2);
        CurrencyExchangeRate."Relational Exch. Rate Amount" := LibraryRandom.RandDec(10, 2);
        CurrencyExchangeRate.Insert();
        exit(CurrencyExchangeRate."Currency Code");
    end;

    local procedure CreateAndUpdateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20]; BankPaymentType: Enum "Bank Payment Type"; Amount: Decimal)
    begin
        CreateGenJournalLineWithAppliesToDocType(
          GenJournalLine, GenJournalLine."Account Type"::"Bank Account", BankAccountNo,
          GenJournalLine."Document Type"::Payment);
        GenJournalLine."Bank Payment Type" := BankPaymentType;
        GenJournalLine.Amount := Amount;
        GenJournalLine.Modify();
    end;

    local procedure CreateSalespersonPurchaser(var SalespersonPurchaser: Record "Salesperson/Purchaser")
    begin
        SalespersonPurchaser.Code := LibraryUTUtility.GetNewCode10();
        SalespersonPurchaser.Insert();
    end;

    local procedure CreateValueEntry(SalespersPurchCode: Code[20])
    var
        ValueEntry: Record "Value Entry";
        ValueEntry2: Record "Value Entry";
    begin
        ValueEntry2.FindLast();
        ValueEntry."Entry No." := ValueEntry2."Entry No." + 1;
        ValueEntry."Source Type" := ValueEntry."Source Type"::Vendor;
        ValueEntry."Item Ledger Entry Type" := ValueEntry."Item Ledger Entry Type"::Purchase;
        ValueEntry."Salespers./Purch. Code" := SalespersPurchCode;
        ValueEntry."Invoiced Quantity" := LibraryRandom.RandDec(10, 2);
        ValueEntry.Insert();
    end;

    local procedure RunCashApplicationReport(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CashApplication: Report "Cash Application";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        CashApplication.SetTableView(VendorLedgerEntry);
        CashApplication.Run();  // Invokes CashApplicationRequestPageHandler.
    end;

    local procedure RunCashRequirementsByDueDateReport(VendorNo: Code[20]; PrintDetail: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CashRequirementsByDueDate: Report "Cash Requirements by Due Date";
    begin
        LibraryVariableStorage.Enqueue(PrintDetail);  // Enqueue value for use in CashRequirementsByDueDateRequestPageHandler.
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        CashRequirementsByDueDate.SetTableView(VendorLedgerEntry);
        CashRequirementsByDueDate.Run();  // Invokes CashRequirementsByDueDateRequestPageHandler.
    end;

    local procedure RunPaymentJournalTestReport(AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournalTest: Report "Payment Journal - Test";
    begin
        GenJournalLine.SetRange("Account No.", AccountNo);
        PaymentJournalTest.SetTableView(GenJournalLine);
        LibraryLowerPermissions.SetJournalsEdit();
        PaymentJournalTest.Run();  // Invokes PaymentJournalTestRequestPageHandler.
    end;

    local procedure RunOutstandingPurchOrderAgingReport(No: Code[20]; PrintDetails: Boolean)
    var
        Vendor: Record Vendor;
        OutstandingPurchOrderAging: Report "Outstanding Purch. Order Aging";
    begin
        LibraryVariableStorage.Enqueue(PrintDetails);  // Enqueue value for use in OutstandingPurchOrderAgingRequestPageHandler.
        Vendor.SetRange("No.", No);
        OutstandingPurchOrderAging.SetTableView(Vendor);
        LibraryLowerPermissions.SetFinancialReporting();
        OutstandingPurchOrderAging.Run();  // Invokes OutstandingPurchOrderAgingRequestPageHandler.
    end;

    local procedure RunOutstandingPurchOrderStatusReport(No: Code[20])
    var
        Vendor: Record Vendor;
        OutstandingPurchOrderStatus: Report "Outstanding Purch.Order Status";
    begin
        Vendor.SetRange("No.", No);
        OutstandingPurchOrderStatus.SetTableView(Vendor);
        LibraryLowerPermissions.SetFinancialReporting();
        OutstandingPurchOrderStatus.Run();  // Invokes OutstandingPurchOrderStatusRequestPageHandler.
    end;

    local procedure RunProjectedCashPaymentsReport(No: Code[20]; PrintTotalsInVendorCurrency: Boolean)
    var
        Vendor: Record Vendor;
        ProjectedCashPayments: Report "Projected Cash Payments";
    begin
        LibraryVariableStorage.Enqueue(PrintTotalsInVendorCurrency);  // Enqueue value for use in ProjectedCashPaymentsRequestPageHandler.
        Vendor.SetRange("No.", No);
        ProjectedCashPayments.SetTableView(Vendor);
        LibraryLowerPermissions.SetAccountPayables();
        ProjectedCashPayments.Run();  // Invokes ProjectedCashPaymentsRequestPageHandler.
    end;

    local procedure RunReconcileAPToGLReport(DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        ReconcileAPToGL: Report "Reconcile AP to GL";
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        ReconcileAPToGL.SetTableView(PurchaseLine);
        LibraryLowerPermissions.SetAccountPayables();
        ReconcileAPToGL.Run();  // Invokes ReconcileAPToGLRequestPageHandler.
    end;

    local procedure RunPurchaserStatByInvoiceReport("Code": Code[20]; PrintDetail: Boolean)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        PurchaserStatByInvoice: Report "Purchaser Stat. by Invoice";
    begin
        LibraryVariableStorage.Enqueue(PrintDetail);  // Enqueue value for use in PurchaserInvoiceByStatRequestPageHandler.
        SalespersonPurchaser.SetRange(Code, Code);
        PurchaserStatByInvoice.SetTableView(SalespersonPurchaser);
        LibraryLowerPermissions.SetAccountPayables();
        PurchaserStatByInvoice.Run();  // Invokes PurchaserInvoiceByStatRequestPageHandler.
    end;

    local procedure RunOutstandingOrderStatByPOReport(No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        OutstandingOrderStatByPO: Report "Outstanding Order Stat. by PO";
    begin
        PurchaseHeader.SetRange("No.", No);
        OutstandingOrderStatByPO.SetTableView(PurchaseHeader);
        LibraryLowerPermissions.SetPurchDocsCreate();
        OutstandingOrderStatByPO.Run();  // Invokes OutstandingOrderStatByPORequestPageHandler.
    end;

    local procedure RunSuggestVendorPaymentsReport(No: Code[20])
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        CreateGenJournalLineWithAppliesToDocType(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, No, GenJournalLine."Document Type"::Payment);
        Vendor.SetRange("No.", No);
        Commit();  // Commit required for explicit commit used in OnPostReport on Report ID:393, Suggest Vendor Payments.
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.SetTableView(Vendor);
        LibraryLowerPermissions.SetAccountPayables();
        SuggestVendorPayments.Run();  // Invokes SuggestVendorPaymentsRequestPageHandler.
    end;

    local procedure RunItemStatisticsByPurchaserReport("Code": Code[20])
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        ItemStatisticsByPurchaser: Report "Item Statistics by Purchaser";
    begin
        SalespersonPurchaser.SetRange(Code, Code);
        ItemStatisticsByPurchaser.SetTableView(SalespersonPurchaser);
        LibraryLowerPermissions.SetAccountPayables();
        ItemStatisticsByPurchaser.Run();  // Invokes ItemStatisticsByPurchaserRequestPageHandler.
    end;

    local procedure UpdateBalanceAccountOnGenJournalLine(GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Bal. Account No." := LibraryUTUtility.GetNewCode();
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine.Modify();
    end;

    local procedure UpdateCurrencyCodeOnVendor(var Vendor: Record Vendor)
    begin
        Vendor."Currency Code" := CreateCurrencyWithExchangeRate();
        Vendor.Modify();
    end;

    local procedure SelectCheckLedgerEntryNo(): Integer
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        if CheckLedgerEntry.FindLast() then
            exit(CheckLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure VerifyReportsPP(ElementName: Text; ExpectedValue: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ElementName, ExpectedValue);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReconcileAPToGLRequestPageHandler(var ReconcileAPToGL: TestRequestPage "Reconcile AP to GL")
    begin
        ReconcileAPToGL.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountCheckDetailsRequestPageHandler(var BankAccountCheckDetails: TestRequestPage "Bank Account - Check Details")
    begin
        BankAccountCheckDetails.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CashApplicationRequestPageHandler(var CashApplication: TestRequestPage "Cash Application")
    begin
        CashApplication.PaymentDate.SetValue(0D);  // Blank Payment Date.
        CashApplication.TakePaymentDiscounts.SetValue(true);
        CashApplication.LastDiscDateToTake.SetValue(CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));  // Last Discount Date less than WORKDATE.
        CashApplication.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CashRequirementsByDueDateRequestPageHandler(var CashRequirementsByDueDate: TestRequestPage "Cash Requirements by Due Date")
    var
        PrintDetail: Variant;
    begin
        LibraryVariableStorage.Dequeue(PrintDetail);
        CashRequirementsByDueDate.ForPaymentOn.SetValue(WorkDate());
        CashRequirementsByDueDate.PrintDetail.SetValue(PrintDetail);
        CashRequirementsByDueDate.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PaymentJournalTestRequestPageHandler(var PaymentJournalTest: TestRequestPage "Payment Journal - Test")
    begin
        PaymentJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OutstandingPurchOrderAgingRequestPageHandler(var OutstandingPurchOrderAging: TestRequestPage "Outstanding Purch. Order Aging")
    var
        PrintDetail: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PrintDetail);
        OutstandingPurchOrderAging.PrintDetail.SetValue(PrintDetail);
        OutstandingPurchOrderAging.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OutstandingPurchOrderStatusRequestPageHandler(var OutstandingPurchOrderStatus: TestRequestPage "Outstanding Purch.Order Status")
    begin
        OutstandingPurchOrderStatus.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProjectedCashPaymentsRequestPageHandler(var ProjectedCashPayments: TestRequestPage "Projected Cash Payments")
    var
        PrintTotalsInVendorCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(PrintTotalsInVendorCurrency);
        ProjectedCashPayments.PrintTotalsInVendorsCurrency.SetValue(PrintTotalsInVendorCurrency);
        ProjectedCashPayments.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProjectedCashPaymentsWithStartDateRequestPageHandler(var ProjectedCashPayments: TestRequestPage "Projected Cash Payments")
    begin
        ProjectedCashPayments.BeginProjectionDate.SetValue(LibraryVariableStorage.DequeueDate());
        ProjectedCashPayments.PrintDetail.SetValue(true);
        ProjectedCashPayments.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaserInvoiceByStatRequestPageHandler(var PurchaserStatByInvoice: TestRequestPage "Purchaser Stat. by Invoice")
    var
        PrintDetail: Variant;
    begin
        LibraryVariableStorage.Dequeue(PrintDetail);
        PurchaserStatByInvoice.PrintDetail.SetValue(PrintDetail);
        PurchaserStatByInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OutstandingOrderStatByPORequestPageHandler(var OutstandingOrderStatByPO: TestRequestPage "Outstanding Order Stat. by PO")
    begin
        OutstandingOrderStatByPO.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    begin
        SuggestVendorPayments.LastPaymentDate.SetValue(WorkDate());
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryUTUtility.GetNewCode10());
        SuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemStatisticsByPurchaserRequestPageHandler(var ItemStatisticsByPurchaser: TestRequestPage "Item Statistics by Purchaser")
    begin
        ItemStatisticsByPurchaser.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure ResolveCaption(CaptionExpression: Text): Text
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CurrencyResult: Text;
    begin
        if not GLSetup.Get() then
            exit(CaptionExpression);

        if GLSetup."LCY Code" = '' then
            CurrencyResult := DefaultTxt
        else
            if not Currency.Get(GLSetup."LCY Code") then
                CurrencyResult := GLSetup."LCY Code"
            else
                CurrencyResult := Currency.Code;

        exit(StrSubstNo(CaptionExpression, CurrencyResult));
    end;
}

