codeunit 144052 "UT REP Purchase & Sales"
{
    // // [FEATURE] [PSREPORTING]
    // Test for feature PSREPORTING - Purchase & Sales Reports.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
#if not CLEAN28
        Assert: Codeunit Assert;
#endif
#if not CLEAN27
        LibraryApplicationArea: Codeunit "Library - Application Area";
#endif        
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
#if not CLEAN28
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryJournals: Codeunit "Library - Journals";
#endif
        CompanyInfoPhoneNoCap: Label 'CompanyInfoPhoneNo';
        IssuedReminderHeaderCap: Label 'No_IssuedReminderHeader';
        CurrentSaveValuesId: Integer;

#if not CLEAN27
    [Test]
    [HandlerFunctions('PurchaseCreditMemoGBRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseCreditMemoGB()
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Report 10578 Purchase - Credit Memo GB.

        // Setup: Create Posted Purchase Credit Memo.
        Initialize();
        CreatePostedPurchaseCreditMemoMultipleLine(PurchCrMemoLine);
        Commit();  // Commit required as it is called explicitly from OnRun Trigger of Codeunit 320 PurchCrMemo-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Purchase - Credit Memo GB");  // Open PurchaseCreditMemoGBRequestPageHandler.

        // Verify: Verify Number and Description on Report Purchase - Credit Memo GB.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_PurchCrMemoLine', PurchCrMemoLine."No.");
        LibraryReportDataset.AssertElementWithValueExists('Desc_PurchCrMemoLine', PurchCrMemoLine.Description);
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceGBRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseInvoiceGB()
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Report 10577 Purchase - Invoice GB.

        // Setup: Create Posted Purchase Invoice.
        Initialize();
        CreatePostedPurchaseInvoiceWithMultipleLine(PurchInvLine);
        Commit();  // Commit required as it is called explicitly from OnRun Trigger of Codeunit 319 Purch. Inv.-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Purchase - Invoice GB");  // Open PurchaseInvoiceGBRequestPageHandler.

        // Verify: Verify Number and Description on Report Purchase - Invoice GB.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_PurchInvLine', PurchInvLine."No.");
        LibraryReportDataset.AssertElementWithValueExists('Description_PurchInvLine', PurchInvLine.Description);
    end;
#endif

    [Test]
    [HandlerFunctions('FinanceChargeMemoLogInteractionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordFinanceChargeMemo()
    var
        IssuedFinChargeMemoNo: Code[20];
    begin
        // Purpose of the test is to validate Issued Fin. Charge Memo Header - OnAfterGetRecord trigger of Report ID - 118 Finance Charge Memo.
        // Setup.
        Initialize();
        IssuedFinChargeMemoNo := CreateIssuedFinChargeMemo();
        Commit();  // Commit required, because it is explicitly called by IncrNoPrinted function of Codeunit ID - 395 FinChrgMemo-Issue.

        // Exercise.
        REPORT.Run(REPORT::"Finance Charge Memo");

        // Verify: Verify Issued Finance Charge Memo Header No on report Finance Charge Memo.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_IssuedFinChrgMemoHeader', IssuedFinChargeMemoNo);
    end;

    [Test]
    [HandlerFunctions('FinanceChargeMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDimensionLoopFinanceChargeMemo()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        IssuedFinChargeMemoNo: Code[20];
    begin
        // Purpose of the test is to validate DimensionLoop - OnAfterGetRecord trigger of Report ID - 118 Finance Charge Memo.
        // Setup.
        Initialize();
        IssuedFinChargeMemoNo := CreateIssuedFinChargeMemo();
        UpdateIssuedFinChargeMemoHeaderDimensionSetID(DimensionSetEntry, IssuedFinChargeMemoNo);
        Commit();  // Commit required, because it is explicitly called by IncrNoPrinted function of Codeunit ID - 395 FinChrgMemo-Issue.

        // Exercise.
        REPORT.Run(REPORT::"Finance Charge Memo");

        // Verify: Verify Dimension Text on report Finance Charge Memo.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'DimText', StrSubstNo('%1 - %2', DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code"));
    end;

    [Test]
    [HandlerFunctions('PurchaseQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseQuote()
    var
        ResponsibilityCenter: Record "Responsibility Center";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate Purchase Header - OnAfterGetRecord trigger of Report ID - 404 Purchase - Quote.
        // Setup.
        Initialize();
        CreateResponsibilityCenter(ResponsibilityCenter);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Quote, ResponsibilityCenter.Code);
        Commit();  // Commit required, because it is explicitly called by OnRun Trigger of Codeunit ID - 317 Purch.Header-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Purchase - Quote");

        // Verify: Verify Purchase Quote No and Company Information Phone No on Report Purchase - Quote.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('PurchHeadNo', PurchaseHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists(CompanyInfoPhoneNoCap, ResponsibilityCenter."Phone No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordRcptHeaderPurchaseReceipt()
    var
        ResponsibilityCenter: Record "Responsibility Center";
        PurchaseReceiptHeaderNo: Code[20];
    begin
        // Purpose of the test is to validate Purch. Rcpt. Header - OnAfterGetRecord trigger of Report ID - 408 Purchase - Receipt.
        // Setup.
        Initialize();
        CreateResponsibilityCenter(ResponsibilityCenter);
        PurchaseReceiptHeaderNo := CreatePurchaseReceiptHeader(ResponsibilityCenter.Code);
        Commit();  // Commit required, because it is explicitly called by OnRun Trigger of Codeunit ID - 318 Purch.Rcpt.-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Purchase - Receipt");

        // Verify: Verify Purchase Receipt Header No and Company Information Phone No on Report Purchase - Receipt.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_PurchRcptHeader', PurchaseReceiptHeaderNo);
        LibraryReportDataset.AssertElementWithValueExists(CompanyInfoPhoneNoCap, ResponsibilityCenter."Phone No.");
    end;

    [Test]
    [HandlerFunctions('ReminderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTypeGLAccountReminder()
    var
        IssuedReminderLine: Record "Issued Reminder Line";
        IssuedReminderHeaderNo: Code[20];
        Amount: Decimal;
    begin
        // Purpose of the test is to validate Issued Reminder Line - OnAfterGetRecord trigger of Report ID - 117 Reminder.
        // Setup.
        Initialize();
        Amount := LibraryRandom.RandDec(10, 2);
        IssuedReminderHeaderNo := CreateIssuedReminder(IssuedReminderLine.Type::"G/L Account", Amount);
        Commit();  // Commit required, because it is explicitly called by IncrNoPrinted function of Codeunit ID - 393 Reminder-Issue.

        // Exercise.
        REPORT.Run(REPORT::Reminder);

        // Verify: Verify Issued Reminder Header Number and Amount on Report Purchase - Receipt.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(IssuedReminderHeaderCap, IssuedReminderHeaderNo);
        LibraryReportDataset.AssertElementWithValueExists('NNCTotalInclVAT', Amount);
    end;

    [Test]
    [HandlerFunctions('ReminderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTypeCustomerLedgerEntryReminder()
    var
        IssuedReminderLine: Record "Issued Reminder Line";
        IssuedReminderHeaderNo: Code[20];
    begin
        // Purpose of the test is to validate Issued Reminder Line - OnAfterGetRecord trigger of Report ID - 117 Reminder.
        // Setup.
        Initialize();
        IssuedReminderHeaderNo := CreateIssuedReminder(IssuedReminderLine.Type::"Customer Ledger Entry", LibraryRandom.RandDec(10, 2));
        Commit();  // Commit required, because it is explicitly called by IncrNoPrinted function of Codeunit ID - 393 Reminder-Issue.

        // Exercise.
        REPORT.Run(REPORT::Reminder);

        // Verify: Verify Issued Reminder Header No on Report Purchase - Receipt.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(IssuedReminderHeaderCap, IssuedReminderHeaderNo);
    end;

    [Test]
    [HandlerFunctions('SalesShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordHeaderSalesShipment()
    var
        SalesShipmentHeaderNo: Code[20];
        PhoneNo: Text[30];
    begin
        // Purpose of the test is to validate Sales Shipment Header - OnAfterGetRecord trigger of Report ID - 208 Sales - Shipment.
        // Setup.
        Initialize();
        SalesShipmentHeaderNo := CreateSalesShipment();
        PhoneNo := UpdateSalesShipmentHeaderResponsibilityCenter(SalesShipmentHeaderNo);
        Commit();  // Commit required, because it is explicitly called by OnRun Trigger of Codeunit ID - 314 Sales Shpt.-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Sales - Shipment");

        // Verify: Verify Sales Shipment Header No and Company Information Phone No on Report Sales - Shipment.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_SalesShptHeader', SalesShipmentHeaderNo);
        LibraryReportDataset.AssertElementWithValueExists(CompanyInfoPhoneNoCap, PhoneNo);
    end;

    [Test]
    [HandlerFunctions('SalesShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordHeaderSalespersonSalesShipment()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentHeaderNo: Code[20];
    begin
        // Purpose of the test is to validate Sales Shipment Header - OnAfterGetRecord trigger of Report ID - 208 Sales - Shipment.
        // Setup.
        Initialize();
        SalesShipmentHeaderNo := CreateSalesShipment();
        UpdateSalesShipmentHeaderWithSalesperson(SalesShipmentHeaderNo);
        Commit();  // Commit required, because it is explicitly called by OnRun Trigger of Codeunit ID - 314 Sales Shpt.-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Sales - Shipment");

        // Verify: Verify Salesperson Text and Reference Text on Report Sales - Shipment.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('SalesPersonText', 'Salesperson');
        LibraryReportDataset.AssertElementWithValueExists('ReferenceText', SalesShipmentHeader.FieldCaption("Your Reference"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerCreateReminders()
    begin
        // Purpose of the test is to validate Customer OnAfterGetRecord trigger of Report ID - 188 Create Reminders.
        Initialize();
        OnAfterGetRecordCreateReminders(false);  // Using False for Use Header Level.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerUseHeaderLevelCreateReminders()
    begin
        // Purpose of the test is to validate Customer OnAfterGetRecord trigger of Report ID - 188 Create Reminders.
        Initialize();
        OnAfterGetRecordCreateReminders(true);  // Using True for Use Header Level.
    end;

#if not CLEAN27
    [Test]
    [HandlerFunctions('ECSalesListReportRPH')]
    [Scope('OnPrem')]
    procedure ECSalesListRequestPageFieldsBasicApplicationArea()
    begin
        // [FEATURE] [ECSL] [Application Area] [UI] [UT]
        // [SCENARIO 331168] ReportLayout and "Create XML File" fields are enabled on EC Sales List Request page when Application Area = #basic
        Initialize();

        // [GIVEN] Enabled Application Area = #basic setup
        LibraryApplicationArea.EnableBasicSetup();
        Commit();

        // [WHEN] Run "EC Sales List" report
        // [THEN] ReportLayout and "Create XML File" fields are enabled (check in RPH)
        REPORT.Run(REPORT::"EC Sales List");
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ECSalesListReportRPH')]
    [Scope('OnPrem')]
    procedure ECSalesListRequestPageFieldsSuiteApplicationArea()
    begin
        // [FEATURE] [ECSL] [Application Area] [UI] [UT]
        // [SCENARIO 331168] ReportLayout and "Create XML File" fields are enabled on EC Sales List Request page when Application Area = #suite
        Initialize();

        // [GIVEN] Enabled Application Area = #suite setup
        LibraryApplicationArea.EnableFoundationSetup();
        Commit();

        // [WHEN] Run "EC Sales List" report
        // [THEN] ReportLayout and "Create XML File" fields are enabled (check in RPH)
        REPORT.Run(REPORT::"EC Sales List");
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;
#endif

#if not CLEAN28
    [Test]
    [Scope('OnPrem')]
    procedure PrintRemittanceAdviceReportSelectionsNotExist()
    var
        ReportSelections: Record "Report Selections";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Report Selections] [Purchase] [Remittance Advice]
        // [SCENARIO 363853] Error is thrown when Stan selects "Print Remittance Advice" on Payment Journal page if Report Selections is not set.
        Initialize();

        // [GIVEN] No report is set for Report Selections "Vendor Remittance".
        // [GIVEN] Payment for Vendor.
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"V.Remittance");
        Assert.RecordIsEmpty(ReportSelections);
        CreatePaymentGenJournalBatch(GenJournalBatch);
        CreateVendorPayment(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, LibraryRandom.RandDecInRange(100, 200, 2));
        Commit();

        // [WHEN] Open "Payment Journal" page with Payment, run "Print Remittance Advice".
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.Filter.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        asserterror PaymentJournal."Print Remi&ttance Advice".Invoke();

        // [THEN] Error "The Report Selections table is empty" is thrown.
        Assert.ExpectedError('The Report Selections table is empty');
        Assert.ExpectedErrorCode('TestWrapped:CSideData');
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintRemittanceAdviceReportSelectionsGenJournalTest()
    var
        ReportSelections: Record "Report Selections";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentJournal: TestPage "Payment Journal";
        DocumentNos: List of [Code[20]];
    begin
        // [FEATURE] [Report Selections] [Purchase] [Remittance Advice]
        // [SCENARIO 363853] Report "General Journal - Test" is run from Report Selections when Stan selects "Print Remittance Advice" on Payment Journal page.
        Initialize();

        // [GIVEN] Report "General Journal - Test" is set as the only report for Report Selections "Vendor Remittance".
        // [GIVEN] Two Payments with Document No. "P1" and "P2" for different Vendors.
        CreateReportSelections(ReportSelections, ReportSelections.Usage::"V.Remittance", '1', Report::"General Journal - Test");
        CreatePaymentGenJournalBatch(GenJournalBatch);
        CreateVendorPayment(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, LibraryRandom.RandDecInRange(100, 200, 2));
        DocumentNos.Add(GenJournalLine."Document No.");
        CreateVendorPayment(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, LibraryRandom.RandDecInRange(100, 200, 2));
        DocumentNos.Add(GenJournalLine."Document No.");
        Commit();

        // [WHEN] Open "Payment Journal" page with Payments "P1" and "P2", run "Print Remittance Advice".
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.Filter.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        PaymentJournal."Print Remi&ttance Advice".Invoke();

        // [THEN] Report "General Journal - Test" is run for Payments "P1" and "P2".
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('GeneralJnlTestCaption', 'General Journal - Test');
        LibraryReportDataset.AssertElementWithValueExists('DocNo_GenJnlLine', DocumentNos.Get(1));
        LibraryReportDataset.AssertElementWithValueExists('DocNo_GenJnlLine', DocumentNos.Get(2));

        // Tear down
        ReportSelections.Delete();
    end;

    [Test]
    [HandlerFunctions('RemittanceAdviceJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintRemittanceAdviceReportSelectionsRemittanceAdviceJournal()
    var
        ReportSelections: Record "Report Selections";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentJournal: TestPage "Payment Journal";
        DocumentNos: List of [Code[20]];
    begin
        // [FEATURE] [Report Selections] [Purchase] [Remittance Advice]
        // [SCENARIO 363853] Report "Remittance Advice - Journal" is run from Report Selections when Stan selects "Print Remittance Advice" on Payment Journal page.
        Initialize();

        // [GIVEN] Report "Remittance Advice - Journal" is set as the only report for Report Selections "Vendor Remittance".
        // [GIVEN] Two Payments with Document No. "P1" and "P2" for different Vendors.
        CreateReportSelections(ReportSelections, ReportSelections.Usage::"V.Remittance", '1', Report::"Remittance Advice - Journal");
        CreatePaymentGenJournalBatch(GenJournalBatch);
        CreateVendorPayment(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, LibraryRandom.RandDecInRange(100, 200, 2));
        DocumentNos.Add(GenJournalLine."Document No.");
        CreateVendorPayment(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, LibraryRandom.RandDecInRange(100, 200, 2));
        DocumentNos.Add(GenJournalLine."Document No.");
        Commit();

        // [WHEN] Open "Payment Journal" page with Payments "P1" and "P2", run "Print Remittance Advice".
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.Filter.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        PaymentJournal."Print Remi&ttance Advice".Invoke();

        // [THEN] Report "Remittance Advice - Journal" is run for Payments "P1" and "P2".
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('RemittanceAdviceCaption', 'Remittance Advice');
        LibraryReportDataset.AssertElementWithValueExists('DocNo_GenJnlLine', DocumentNos.Get(1));
        LibraryReportDataset.AssertElementWithValueExists('DocNo_GenJnlLine', DocumentNos.Get(2));

        // Tear down
        ReportSelections.Delete();
    end;
#endif

    local procedure OnAfterGetRecordCreateReminders(UseHeaderLevel: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
    begin
        // Setup: Create Customer Ledger Entry and Detailed Customer Ledger Entry.
        CreateCustomerLedgerEntry(CustLedgerEntry, UseHeaderLevel);  // Use Header Level required inside CreateRemindersRequestPageHandler.
        CreateAndUpdateDetailedCustomerLedgerEntry(CustLedgerEntry);
        Commit();  // Commit required as it is called explicitly from OnPostDataItem Trigger of Report 188 Create Reminders.

        // Exercise.
        RunCreateRemindersReport(CustLedgerEntry."Customer No.", UseHeaderLevel);

        // Verify: Verify Remaining Amount on Reminder Line and Use Header Level on Reminder Header.
        CustLedgerEntry.CalcFields(Amount);
        SelectReminderLine(ReminderLine, CustLedgerEntry."Entry No.");
        ReminderLine.TestField("Remaining Amount", CustLedgerEntry.Amount);
        ReminderHeader.Get(ReminderLine."Reminder No.");
        ReminderHeader.TestField("Use Header Level", UseHeaderLevel);
    end;

    local procedure Initialize()
    var
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
    begin
        LibraryVariableStorage.Clear();
        DeleteObjectOptionsIfNeeded();

        if FeatureKey.Get('ReminderTermsCommunicationTexts') then begin
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
        end;
        if FeatureKeyUpdateStatus.Get('ReminderTermsCommunicationTexts', CompanyName()) then begin
            FeatureKeyUpdateStatus."Feature Status" := FeatureKeyUpdateStatus."Feature Status"::Disabled;
            FeatureKeyUpdateStatus.Modify();
        end;
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerPostingGroupCode: Code[20];
    begin
        CustomerPostingGroupCode := CreateVATAndCustomerPostingSetup(VATPostingSetup);
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer."Reminder Terms Code" := CreateReminderTerms();
        Customer."Customer Posting Group" := CustomerPostingGroupCode;
        Customer."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateGLEntry(var GLEntry: Record "G/L Entry")
    var
        GLEntry2: Record "G/L Entry";
    begin
        if GLEntry2.FindLast() then;
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."G/L Account No." := LibraryUTUtility.GetNewCode();
        GLEntry."Document No." := LibraryUTUtility.GetNewCode();
        GLEntry."Transaction No." := SelectGLEntryTransactionNo();
        GLEntry.Insert();
    end;

#if not CLEAN27
    local procedure CreatePostedPurchaseInvoiceWithMultipleLine(var PurchInvLine: Record "Purch. Inv. Line")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader."No." := LibraryUTUtility.GetNewCode();
        PurchInvHeader.Insert();
        CreatePostedPurchaseInvoiceLine(PurchInvLine, PurchInvLine.Type::Item, PurchInvHeader."No.", LibraryUTUtility.GetNewCode());
        CreatePostedPurchaseInvoiceLine(PurchInvLine, PurchInvLine.Type::Item, PurchInvHeader."No.", '');  // Blank value for Number.
        LibraryVariableStorage.Enqueue(PurchInvHeader."No.");  // Enqueue required for PurchaseCreditMemoGBRequestPageHandler.
    end;

    local procedure CreatePostedPurchaseInvoiceLine(var PurchInvLine: Record "Purch. Inv. Line"; Type: Enum "Purchase Line Type"; DocumentNo: Code[20]; No: Code[20])
    begin
        PurchInvLine."Line No." := SelectPurchaseInvoiceLineNo(DocumentNo);
        PurchInvLine."Document No." := DocumentNo;
        PurchInvLine.Type := Type;
        PurchInvLine."No." := No;
        PurchInvLine.Description := LibraryUTUtility.GetNewCode();
        PurchInvLine.Insert();
    end;

    local procedure CreatePostedPurchaseCreditMemoMultipleLine(var PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHeader."No." := LibraryUTUtility.GetNewCode();
        PurchCrMemoHeader.Insert();
        CreatePostedPurchaseCreditMemoLine(
          PurchCrMemoLine, PurchCrMemoLine.Type::Item, PurchCrMemoHeader."No.", LibraryUTUtility.GetNewCode());
        CreatePostedPurchaseCreditMemoLine(PurchCrMemoLine, PurchCrMemoLine.Type::Item, PurchCrMemoHeader."No.", '');  // Blank value for - Number.
        LibraryVariableStorage.Enqueue(PurchCrMemoHeader."No.");  // Enqueue required for PurchaseCreditMemoGBRequestPageHandler.
    end;

    local procedure CreatePostedPurchaseCreditMemoLine(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; Type: Enum "Purchase Line Type"; DocumentNo: Code[20]; No: Code[20])
    begin
        PurchCrMemoLine."Line No." := SelectPurchaseCreditMemoLineNo(DocumentNo);
        PurchCrMemoLine."Document No." := DocumentNo;
        PurchCrMemoLine.Type := Type;
        PurchCrMemoLine."No." := No;
        PurchCrMemoLine.Description := LibraryUTUtility.GetNewCode();
        PurchCrMemoLine.Insert();
    end;
#endif

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ResponsibilityCenter: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Buy-from Vendor No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Vendor Cr. Memo No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Vendor Invoice No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Responsibility Center" := ResponsibilityCenter;
        PurchaseHeader.Insert();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine.Quantity := LibraryRandom.RandDec(10, 2);
        PurchaseLine."Amount Including VAT" := LibraryRandom.RandDec(10, 2);
        PurchaseLine.Insert();

        // Enqueue value for UnpostedPurchasesRequestPageHandler.
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        LibraryVariableStorage.Enqueue(PurchaseHeader."Document Type");
    end;

    local procedure CreateReminderTerms(): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        ReminderTerms.Code := LibraryUTUtility.GetNewCode10();
        ReminderTerms.Insert();
        CreateReminderLevel(ReminderTerms.Code);
        exit(ReminderTerms.Code);
    end;

    local procedure CreateReminderLevel(ReminderTermsCode: Code[10])
    var
        ReminderLevel: Record "Reminder Level";
    begin
        ReminderLevel."Reminder Terms Code" := ReminderTermsCode;
        ReminderLevel."No." := 1;  // Using 1 for Reminder Level first.
        Evaluate(ReminderLevel."Grace Period", ('<' + Format(LibraryRandom.RandInt(5)) + 'D>'));
        ReminderLevel."Additional Fee (LCY)" := LibraryRandom.RandDec(10, 2);
        ReminderLevel.Insert();
    end;

    local procedure CreateCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; PrintCustLedgerDetails: Boolean)
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
    begin
        CreateGLEntry(GLEntry);
        if CustLedgerEntry2.FindLast() then;
        CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Customer No." := CreateCustomer();
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Positive := true;
        CustLedgerEntry."Due Date" := WorkDate();
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Transaction No." := GLEntry."Transaction No.";
        CustLedgerEntry."Closed by Entry No." := CustLedgerEntry."Entry No.";
        CustLedgerEntry."Pmt. Disc. Given (LCY)" := LibraryRandom.RandDec(10, 2);
        CustLedgerEntry.Insert();

        LibraryVariableStorage.Enqueue(CustLedgerEntry."Customer No.");
        LibraryVariableStorage.Enqueue(PrintCustLedgerDetails);
    end;

    local procedure CreateDetailedCustomerLedgerEntry(CustLedgerEntryNo: Integer; TransactionNo: Integer): Integer
    var
        DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        if DetailedCustLedgEntry2.FindLast() then;
        DetailedCustLedgEntry."Entry No." := DetailedCustLedgEntry2."Entry No." + 1;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntryNo;
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::"Realized Loss";
        DetailedCustLedgEntry."Amount (LCY)" := LibraryRandom.RandDec(10, 2);
        DetailedCustLedgEntry."Transaction No." := TransactionNo;
        DetailedCustLedgEntry.Insert(true);
        exit(DetailedCustLedgEntry."Entry No.");
    end;

    local procedure CreateAndUpdateDetailedCustomerLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Get(CreateDetailedCustomerLedgerEntry(CustLedgerEntry."Entry No.", LibraryRandom.RandInt(10)));  // Using Random value for Transaction Number.
        DetailedCustLedgEntry."Document No." := CustLedgerEntry."Document No.";
        DetailedCustLedgEntry."Document Type" := DetailedCustLedgEntry."Document Type"::Invoice;
        DetailedCustLedgEntry."Customer No." := CustLedgerEntry."Customer No.";
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::"Initial Entry";
        DetailedCustLedgEntry.Amount := LibraryRandom.RandDec(10, 2);
        DetailedCustLedgEntry.Modify();
    end;

    local procedure CreateGLAccount(VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount."VAT Prod. Posting Group" := VATProdPostingGroup;
        GLAccount."Gen. Prod. Posting Group" := CreateGeneralPostingSetup(VATProdPostingGroup);
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateGenProductPostingGroup(DefVATProdPostingGroup: Code[20]): Code[20]
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GenProductPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        GenProductPostingGroup."Def. VAT Prod. Posting Group" := DefVATProdPostingGroup;
        GenProductPostingGroup.Insert();
        exit(GenProductPostingGroup.Code);
    end;

    local procedure CreateGeneralPostingSetup(DefVATProdPostingGroup: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup."Gen. Prod. Posting Group" := CreateGenProductPostingGroup(DefVATProdPostingGroup);
        GeneralPostingSetup.Insert();
        exit(GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

#if not CLEAN28
    local procedure CreatePaymentGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateVendorPayment(var GenJournalLine: Record "Gen. Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; LineAmount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLine2(
            GenJournalLine, JournalTemplateName, JournalBatchName, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), GenJournalLine."Bal. Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNo(), LineAmount);
    end;
#endif

    local procedure CreateDimensionSetEntry(var DimensionSetEntry: Record "Dimension Set Entry")
    var
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry2: Record "Dimension Set Entry";
    begin
        DimensionValue."Dimension Code" := LibraryUTUtility.GetNewCode();
        DimensionValue.Code := LibraryUTUtility.GetNewCode();
        DimensionValue.Insert();

        if DimensionSetEntry2.FindLast() then
            DimensionSetEntry."Dimension Set ID" := DimensionSetEntry2."Dimension Set ID" + 1
        else
            DimensionSetEntry."Dimension Set ID" := 1;
        DimensionSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        DimensionSetEntry."Dimension Value Code" := DimensionValue.Code;
        DimensionSetEntry.Insert();
    end;

    local procedure CreateVATProductPostingGroup(): Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        VATProductPostingGroup.Insert();
        exit(VATProductPostingGroup.Code);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup."VAT Bus. Posting Group" := LibraryUTUtility.GetNewCode10();
        VATPostingSetup."VAT Prod. Posting Group" := CreateVATProductPostingGroup();
        VATPostingSetup.Insert();
    end;

    local procedure CreateCustomerPostingGroup(VATProdPostingGroup: Code[20]): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccountNo: Code[20];
    begin
        GLAccountNo := CreateGLAccount(VATProdPostingGroup);
        CustomerPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        CustomerPostingGroup."Additional Fee Account" := GLAccountNo;
        CustomerPostingGroup."Interest Account" := GLAccountNo;
        CustomerPostingGroup.Insert();
        exit(CustomerPostingGroup.Code);
    end;

    local procedure CreateIssuedFinChargeMemo(): Code[20]
    var
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerPostingGroupCode: Code[20];
    begin
        CustomerPostingGroupCode := CreateVATAndCustomerPostingSetup(VATPostingSetup);
        IssuedFinChargeMemoHeader."No." := LibraryUTUtility.GetNewCode();
        IssuedFinChargeMemoHeader."Customer Posting Group" := CustomerPostingGroupCode;
        IssuedFinChargeMemoHeader."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        IssuedFinChargeMemoHeader.Insert();

        IssuedFinChargeMemoLine."Finance Charge Memo No." := IssuedFinChargeMemoHeader."No.";
        IssuedFinChargeMemoLine."Line No." := LibraryRandom.RandInt(10);
        IssuedFinChargeMemoLine.Insert();
        LibraryVariableStorage.Enqueue(IssuedFinChargeMemoHeader."No.");  // Required inside FinanceChargeMemoRequestPageHandler and FinanceChargeMemoLoginteractionRequestPageHandler.
        exit(IssuedFinChargeMemoHeader."No.")
    end;

    local procedure CreateIssuedReminder(Type: Enum "Reminder Source Type"; Amount: Decimal): Code[20]
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderLine: Record "Issued Reminder Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerPostingGroupCode: Code[20];
    begin
        CustomerPostingGroupCode := CreateVATAndCustomerPostingSetup(VATPostingSetup);
        IssuedReminderHeader."No." := LibraryUTUtility.GetNewCode();
        IssuedReminderHeader."Customer Posting Group" := CustomerPostingGroupCode;
        IssuedReminderHeader."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        IssuedReminderHeader."Currency Code" := LibraryUTUtility.GetNewCode10();
        IssuedReminderHeader.Insert();

        IssuedReminderLine."Reminder No." := IssuedReminderHeader."No.";
        IssuedReminderLine.Amount := Amount;
        IssuedReminderLine.Type := Type;
        IssuedReminderLine.Insert();
        LibraryVariableStorage.Enqueue(IssuedReminderHeader."No.");  // Required inside ReminderRequestPageHandler.
        exit(IssuedReminderHeader."No.");
    end;

    local procedure CreateResponsibilityCenter(var ResponsibilityCenter: Record "Responsibility Center")
    begin
        ResponsibilityCenter.Code := LibraryUTUtility.GetNewCode10();
        ResponsibilityCenter."Phone No." := LibraryUTUtility.GetNewCode();
        ResponsibilityCenter.Insert();
    end;

    local procedure CreatePurchaseReceiptHeader(ResponsibilityCenter: Code[10]): Code[20]
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader."No." := LibraryUTUtility.GetNewCode();
        PurchRcptHeader."Responsibility Center" := ResponsibilityCenter;
        PurchRcptHeader.Insert();
        LibraryVariableStorage.Enqueue(PurchRcptHeader."No.");  // Required inside PurchaseReceiptRequestPageHandler.
        exit(PurchRcptHeader."No.");
    end;

    local procedure CreateSalesShipment(): Code[20]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentHeader."No." := LibraryUTUtility.GetNewCode();
        SalesShipmentHeader.Insert();
        SalesShipmentLine."Document No." := SalesShipmentHeader."No.";
        SalesShipmentLine.Insert();
        LibraryVariableStorage.Enqueue(SalesShipmentHeader."No.");  // Required inside SalesShipmentRequestPageHandler.
        exit(SalesShipmentHeader."No.");
    end;

    local procedure CreateSalespersonPurchaser(): Code[10]
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        SalespersonPurchaser.Code := LibraryUTUtility.GetNewCode10();
        SalespersonPurchaser.Insert();
        exit(SalespersonPurchaser.Code);
    end;

    local procedure CreateVATAndCustomerPostingSetup(var VATPostingSetup: Record "VAT Posting Setup") CustomerPostingGroupCode: Code[20]
    begin
        CreateVATPostingSetup(VATPostingSetup);
        CustomerPostingGroupCode := CreateCustomerPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
    end;

#if not CLEAN28
    local procedure CreateReportSelections(var ReportSelections: Record "Report Selections"; ReportUsage: Enum "Report Selection Usage"; SequenceCode: Code[10]; ReportID: Integer)
    begin
        ReportSelections.Init();
        ReportSelections.Validate(Usage, ReportUsage);
        ReportSelections.Validate(Sequence, SequenceCode);
        ReportSelections.Validate("Report ID", ReportID);
        ReportSelections.Insert(true);
    end;
#endif

    local procedure RunCreateRemindersReport(CustomerNo: Code[20]; UseHeaderLevel: Boolean)
    var
        Customer: Record Customer;
        CreateReminders: Report "Create Reminders";
    begin
        Customer.SetRange("No.", CustomerNo);
        CreateReminders.SetTableView(Customer);
        CreateReminders.InitializeRequest(CalcDate('<CY>', WorkDate()), WorkDate(), true, UseHeaderLevel, false);  // Calculation done for Document Date, TRUE for OverDueEntries, FALSE for Include Entries On Hold.
        CreateReminders.UseRequestPage(false);
        CreateReminders.Run();
    end;

    local procedure UpdateIssuedFinChargeMemoHeaderDimensionSetID(var DimensionSetEntry: Record "Dimension Set Entry"; IssuedFinChargeMemoNo: Code[20])
    var
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        CreateDimensionSetEntry(DimensionSetEntry);
        IssuedFinChargeMemoHeader.Get(IssuedFinChargeMemoNo);
        IssuedFinChargeMemoHeader."Dimension Set ID" := DimensionSetEntry."Dimension Set ID";
        IssuedFinChargeMemoHeader.Modify();
    end;

    local procedure UpdateSalesShipmentHeaderWithSalesperson(SalesShipmentHeaderNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.Get(SalesShipmentHeaderNo);
        SalesShipmentHeader."Salesperson Code" := CreateSalespersonPurchaser();
        SalesShipmentHeader."Your Reference" := LibraryUTUtility.GetNewCode();
        SalesShipmentHeader.Modify();
    end;

    local procedure UpdateSalesShipmentHeaderResponsibilityCenter(SalesShipmentHeaderNo: Code[20]): Text[30]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        CreateResponsibilityCenter(ResponsibilityCenter);
        SalesShipmentHeader.Get(SalesShipmentHeaderNo);
        SalesShipmentHeader."Responsibility Center" := ResponsibilityCenter.Code;
        SalesShipmentHeader.Modify();
        exit(ResponsibilityCenter."Phone No.");
    end;

    local procedure SelectGLEntryTransactionNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Transaction No.");
        if GLEntry.FindLast() then;
        exit(GLEntry."Transaction No." + 1);
    end;

#if not CLEAN27
    local procedure SelectPurchaseInvoiceLineNo(DocumentNo: Code[20]): Integer
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        if PurchInvLine.FindLast() then
            exit(PurchInvLine."Line No." + 1);
        exit(1);
    end;

    local procedure SelectPurchaseCreditMemoLineNo(DocumentNo: Code[20]): Integer
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        if PurchCrMemoLine.FindLast() then
            exit(PurchCrMemoLine."Line No." + 1);
        exit(1);
    end;
#endif

    local procedure SelectReminderLine(var ReminderLine: Record "Reminder Line"; EntryNo: Integer)
    begin
        ReminderLine.SetRange(Type, ReminderLine.Type::"Customer Ledger Entry");
        ReminderLine.SetRange("Document Type", ReminderLine."Document Type"::Invoice);
        ReminderLine.SetRange("Entry No.", EntryNo);
        ReminderLine.FindFirst();
    end;

    local procedure SaveAsXMLFinanceChargeMemoReport(FinanceChargeMemo: TestRequestPage "Finance Charge Memo"; ShowInternalInformation: Boolean; LogInteraction: Boolean)
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        FinanceChargeMemo."Issued Fin. Charge Memo Header".SetFilter("No.", No);
        FinanceChargeMemo.ShowInternalInformation.SetValue(ShowInternalInformation);
        FinanceChargeMemo.LogInteraction.SetValue(LogInteraction);
        FinanceChargeMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

#if not CLEAN27
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoGBRequestPageHandler(var PurchaseCreditMemoGB: TestRequestPage "Purchase - Credit Memo GB")
    var
        No: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Purchase - Credit Memo GB";
        LibraryVariableStorage.Dequeue(No);
        PurchaseCreditMemoGB."Purch. Cr. Memo Hdr.".SetFilter("No.", No);
        PurchaseCreditMemoGB.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceGBRequestPageHandler(var PurchaseInvoiceGB: TestRequestPage "Purchase - Invoice GB")
    var
        No: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Purchase - Invoice GB";
        LibraryVariableStorage.Dequeue(No);
        PurchaseInvoiceGB."Purch. Inv. Header".SetFilter("No.", No);
        PurchaseInvoiceGB.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
#endif

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoLogInteractionRequestPageHandler(var FinanceChargeMemo: TestRequestPage "Finance Charge Memo")
    begin
        CurrentSaveValuesId := REPORT::"Finance Charge Memo";
        SaveAsXMLFinanceChargeMemoReport(FinanceChargeMemo, false, true);  // ShowInternalInformation - FALSE and LogInteraction - TRUE.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoRequestPageHandler(var FinanceChargeMemo: TestRequestPage "Finance Charge Memo")
    begin
        CurrentSaveValuesId := REPORT::"Finance Charge Memo";
        SaveAsXMLFinanceChargeMemoReport(FinanceChargeMemo, true, false);  // ShowInternalInformation - TRUE and LogInteraction - FALSE.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseQuoteRequestPageHandler(var PurchaseQuote: TestRequestPage "Purchase - Quote")
    var
        No: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Purchase - Quote";
        LibraryVariableStorage.Dequeue(No);
        PurchaseQuote."Purchase Header".SetFilter("No.", No);
        PurchaseQuote.LogInteraction.SetValue(true);
        PurchaseQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseReceiptRequestPageHandler(var PurchaseReceipt: TestRequestPage "Purchase - Receipt")
    var
        No: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Purchase - Receipt";
        LibraryVariableStorage.Dequeue(No);
        PurchaseReceipt."Purch. Rcpt. Header".SetFilter("No.", No);
        PurchaseReceipt.LogInteraction.SetValue(true);
        PurchaseReceipt."Show Correction Lines".SetValue(true);
        PurchaseReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderRequestPageHandler(var Reminder: TestRequestPage Reminder)
    var
        No: Variant;
    begin
        CurrentSaveValuesId := REPORT::Reminder;
        LibraryVariableStorage.Dequeue(No);
        Reminder."Issued Reminder Header".SetFilter("No.", No);
        Reminder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentRequestPageHandler(var SalesShipment: TestRequestPage "Sales - Shipment")
    var
        No: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Sales - Shipment";
        LibraryVariableStorage.Dequeue(No);
        SalesShipment."Sales Shipment Header".SetFilter("No.", No);
        SalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure DeleteObjectOptionsIfNeeded()
    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
    begin
        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);
    end;

#if not CLEAN27
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ECSalesListReportRPH(var ECSalesList: TestRequestPage "EC Sales List")
    begin
        Assert.IsTrue(ECSalesList."Create XML File".Visible(), '');
        Assert.IsTrue(ECSalesList."Create XML File".Enabled(), '');
    end;
#endif

    [RequestPageHandler]
    procedure GeneralJournalTestRequestPageHandler(var GeneralJournalTest: TestRequestPage "General Journal - Test");
    begin
        GeneralJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure RemittanceAdviceJournalRequestPageHandler(var RemittanceAdviceJournal: TestRequestPage "Remittance Advice - Journal");
    begin
        RemittanceAdviceJournal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

