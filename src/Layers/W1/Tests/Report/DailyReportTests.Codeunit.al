codeunit 133769 "Daily Report Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Day Book Report]
        isInitialized := false;
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryXMLRead: Codeunit "Library - XML Read";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        LedgerFilterTxt: Label '%1: %2, %3: %4';
        AmountCapTxt: Label 'All_amounts_are_in___GLSetup__LCY_Code_';
        AmountFilterTxt: Label '%1 %2%3';
        AmountTxt: Label 'All amounts are in';
        VATAmountCapTxt: Label 'VATAmount';
        VATBaseCapTxt: Label 'VATBase';
        ActualAmountCapTxt: Label 'ActualAmount';
        VATEntryAmountCapTxt: Label 'VAT_Entry_Amount';
        CurrentSaveValuesId: Integer;

    [Test]
    [HandlerFunctions('RHDayBookVATEntry')]
    [Scope('OnPrem')]
    procedure TestDayBookVATEntry()
    begin
        // [FEATURE] [VAT]
        InitReports();
        REPORT.Run(REPORT::"Day Book VAT Entry");
    end;

    [Test]
    [HandlerFunctions('RHDayBookCustLedgerEntry')]
    [Scope('OnPrem')]
    procedure TestDayBookCustLedgerEntry()
    begin
        // [FEATURE] [Sales]
        InitReports();
        REPORT.Run(REPORT::"Day Book Cust. Ledger Entry");
    end;

    [Test]
    [HandlerFunctions('RHDayBookVendorLedgerEntry')]
    [Scope('OnPrem')]
    procedure TestDayBookVendorLedgerEntry()
    begin
        // [FEATURE] [Purchase]
        InitReports();
        REPORT.Run(REPORT::"Day Book Vendor Ledger Entry");
    end;

    [Test]
    [HandlerFunctions('DayBookVATEntryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATEntryPurchWithVendorDayBookVATEntry()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO] Validate OnAfterGetRecord Trigger for VAT Entry Type - Purchase with Vendor of Report 2500 - Day Book VAT Entry.
        DayBookVATEntryReport(VATEntry.Type::Purchase, CreateVendor());
    end;

    [Test]
    [HandlerFunctions('DayBookVATEntryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATEntrySaleWithCustDayBookVATEntry()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO] Validate OnAfterGetRecord Trigger for VAT Entry Type - Sale with Customer of Report 2500 - Day Book VAT Entry.
        DayBookVATEntryReport(VATEntry.Type::Sale, CreateCustomer());
    end;

    [Test]
    [HandlerFunctions('DayBookVATEntryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATEntryTypeSettlementDayBookVATEntry()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO] Validate OnAfterGetRecord Trigger for VAT Entry Type - Settlement of Report 2500 - Day Book VAT Entry.
        DayBookVATEntryReport(VATEntry.Type::Settlement, '');  // Taken blank value for BillToPayToNo.
    end;

    [Test]
    [HandlerFunctions('DayBookVATEntryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATEntrySaleWithoutCustDayBookVATEntry()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO] Validate OnAfterGetRecord Trigger for VAT Entry Type - Sale without Customer of Report 2500 - Day Book VAT Entry.
        DayBookVATEntryReport(VATEntry.Type::Sale, LibraryUTUtility.GetNewCode());
    end;

    [Test]
    [HandlerFunctions('DayBookVATEntryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATEntryPurchWithoutVendorDayBookVATEntry()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO] Validate OnAfterGetRecord Trigger for VAT Entry Type - Purchase without Vendor of Report 2500 - Day Book VAT Entry.
        DayBookVATEntryReport(VATEntry.Type::Purchase, LibraryUTUtility.GetNewCode());
    end;

    [Test]
    [HandlerFunctions('DayBookCustLedgerEntryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordLedgerEntryDayBookCustLedgerEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Validate Customer Ledger Entry - OnAfterGetRecord trigger of Report ID - 2501 Day Book Cust. Ledger Entry.

        // Setup: Create Customer Ledger Entry and VAT Entry.
        LibraryVariableStorage.Clear();
        DeleteObjectOptionsIfNeeded();
        CreateCustomerLedgerEntry(CustLedgerEntry, false);  // Print Customer Ledger Details, Print G/L Entry Details - FALSE on DayBookCustLedgerEntryRequestPageHandler.
        CreateVATEntry(VATEntry, CustLedgerEntry."Transaction No.", VATEntry.Type::" ", LibraryRandom.RandDec(10, 2), '', '', '');

        // Exercise.
        REPORT.Run(REPORT::"Day Book Cust. Ledger Entry");  // Opens DayBookCustLedgerEntryRequestPageHandler.

        // Verify: Verify Customer Ledger Entry Filters, VAT Amount and VAT Base on Report Day Book Customer Ledger Entry.
        GeneralLedgerSetup.Get();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'CustLedgFilter',
          StrSubstNo(
            LedgerFilterTxt, CustLedgerEntry.FieldCaption("Customer No."), CustLedgerEntry."Customer No.",
            CustLedgerEntry.FieldCaption("Posting Date"), CustLedgerEntry."Posting Date"));
        LibraryReportDataset.AssertElementWithValueExists(
          AmountCapTxt, StrSubstNo(AmountFilterTxt, AmountTxt, GeneralLedgerSetup."LCY Code", '.'));
        LibraryReportDataset.AssertElementWithValueExists(VATAmountCapTxt, -VATEntry.Amount);
        LibraryReportDataset.AssertElementWithValueExists(VATBaseCapTxt, -VATEntry.Base);
    end;

    [Test]
    [HandlerFunctions('DayBookCustLedgerEntryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLEntryDayBookCustLedgerEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Validate G/L Entry - OnAfterGetRecord trigger of Report ID - 2501 Day Book Cust. Ledger Entry.

        // Setup: Create Customer Ledger Entry, VAT Entry and Detailed Customer Ledger Entry.
        LibraryVariableStorage.Clear();
        DeleteObjectOptionsIfNeeded();
        CreateCustomerLedgerEntry(CustLedgerEntry, true);  // Print Customer Ledger Details, Print G/L Entry Details - TRUE on DayBookCustLedgerEntryRequestPageHandler.
        CreateVATEntry(VATEntry, CustLedgerEntry."Transaction No.", VATEntry.Type::" ", LibraryRandom.RandDec(10, 2), '', '', '');
        CreateDetailedCustomerLedgerEntry(CustLedgerEntry."Entry No.", CustLedgerEntry."Transaction No.");

        // Exercise.
        REPORT.Run(REPORT::"Day Book Cust. Ledger Entry");  // Opens DayBookCustLedgerEntryRequestPageHandler.

        // Verify: Verify Actual Amount, Payment Discount Given (LCY), Amount (LCY), VAT Amount and VAT Base on Report Day Book Customer Ledger Entry.
        CustLedgerEntry.CalcFields("Amount (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          ActualAmountCapTxt, CustLedgerEntry."Amount (LCY)" + CustLedgerEntry."Pmt. Disc. Given (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('PmtDiscGiven', -CustLedgerEntry."Pmt. Disc. Given (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('Cust__Ledger_Entry___Amount__LCY__', CustLedgerEntry."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(VATAmountCapTxt, -VATEntry.Amount);
        LibraryReportDataset.AssertElementWithValueExists(VATBaseCapTxt, -VATEntry.Base);
    end;

    [Test]
    [HandlerFunctions('DayBookVendorLedgerEntryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordLedgerEntryDayBookVendorLedgerEntry()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Validate Vendor Ledger Entry - OnAfterGetRecord trigger of Report ID - 10535 Day Book Vendor Ledger Entry.

        // Setup: Create Vendor Ledger Entry and VAT Entry.
        LibraryVariableStorage.Clear();
        DeleteObjectOptionsIfNeeded();
        CreateVendorLedgerEntry(VendorLedgerEntry, '', LibraryUTUtility.GetNewCode(), false, 0, VendorLedgerEntry."Document Type"::Invoice);  // Print Vender Ledger Details - FALSE on DayBookVendorLedgerEntryRequestPageHandler and using 0 for Amount to Apply.
        CreateVATEntry(VATEntry, VendorLedgerEntry."Transaction No.", VATEntry.Type::" ", LibraryRandom.RandDec(10, 2), '', '', '');

        // Exercise.
        REPORT.Run(REPORT::"Day Book Vendor Ledger Entry");  // Opens DayBookVendorLedgerEntryRequestPageHandler.

        // Verify: Verify Vendor Ledger Entry Filters, VAT Amount and VAT Base on Report Day Book Vendor Ledger Entry.
        GeneralLedgerSetup.Get();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'VendLedgFilter',
          StrSubstNo(
            LedgerFilterTxt, VendorLedgerEntry.FieldCaption("Vendor No."), VendorLedgerEntry."Vendor No.",
            VendorLedgerEntry.FieldCaption("Posting Date"), VendorLedgerEntry."Posting Date"));
        LibraryReportDataset.AssertElementWithValueExists(
          AmountCapTxt, StrSubstNo(AmountFilterTxt, AmountTxt, GeneralLedgerSetup."LCY Code", ''));
        LibraryReportDataset.AssertElementWithValueExists(VATAmountCapTxt, -VATEntry.Amount);
        LibraryReportDataset.AssertElementWithValueExists(VATBaseCapTxt, -VATEntry.Base);
    end;

    [Test]
    [HandlerFunctions('DayBookVendorLedgerEntryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLEntryDayBookVendorLedgerEntry()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Validate G/L Entry - OnAfterGetRecord trigger of Report ID - 2502 Day Book Vendor Ledger Entry.

        // Setup: Create Vendor Ledger Entry, VAT Entry and Detailed Vendor Ledger Entry.
        LibraryVariableStorage.Clear();
        DeleteObjectOptionsIfNeeded();
        CreateVendorLedgerEntry(VendorLedgerEntry, '', LibraryUTUtility.GetNewCode(), true, 0, VendorLedgerEntry."Document Type"::Invoice);  // Print Vender Ledger Details - TRUE on DayBookVendorLedgerEntryRequestPageHandler and using 0 for Amount to Apply.
        CreateVATEntry(VATEntry, VendorLedgerEntry."Transaction No.", VATEntry.Type::" ", LibraryRandom.RandDec(10, 2), '', '', '');
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", VendorLedgerEntry."Transaction No.");

        // Exercise.
        REPORT.Run(REPORT::"Day Book Vendor Ledger Entry");  // Opens DayBookVendorLedgerEntryRequestPageHandler.

        // Verify: Verify Actual Amount, Payment Discount Received (LCY), Amount (LCY), VAT Amount and VAT Base on Report Day Book Vendor Ledger Entry.
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          ActualAmountCapTxt, VendorLedgerEntry."Amount (LCY)" + VendorLedgerEntry."Pmt. Disc. Rcd.(LCY)");
        LibraryReportDataset.AssertElementWithValueExists('PmtDiscRcd', -VendorLedgerEntry."Pmt. Disc. Rcd.(LCY)");
        LibraryReportDataset.AssertElementWithValueExists('Vendor_Ledger_Entry__Amount__LCY__', VendorLedgerEntry."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(VATAmountCapTxt, -VATEntry.Amount);
        LibraryReportDataset.AssertElementWithValueExists(VATBaseCapTxt, -VATEntry.Base);
    end;

    [Test]
    [HandlerFunctions('DayBookVATEntrySetFiltersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DayBookVATEntryCustomerVendorWithSameNos()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        CustVendNo: Code[20];
        DocNoFilter: Text;
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 311613] "Sell-to/Buy-from Name" on Day Book VAT Entry report results in case Customer and Vendor with the same Nos.

        // [GIVEN] Customer with "No." = "A1", Name = "CUST"; Vendor with "No." = "A1", Name = "VEND".
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Customer.Rename(Vendor."No.");
        CustVendNo := Customer."No.";

        // [GIVEN] Sales Invoice for "A1", Posting Date = "D1".
        // [GIVEN] Purchase Invoice for "A1", Posting Date = "D1" + 1.
        // [GIVEN] Sales Invoice for "A1", Posting Date = "D1" + 1.
        DocNoFilter += CreateAndPostSalesInvoice(CustVendNo, WorkDate() - 1);
        DocNoFilter += '|';
        DocNoFilter += CreateAndPostPurchaseInvoice(CustVendNo, WorkDate());
        DocNoFilter += '|';
        DocNoFilter += CreateAndPostSalesInvoice(CustVendNo, WorkDate());
        LibraryVariableStorage.Enqueue(DocNoFilter);
        LibraryVariableStorage.Enqueue(StrSubstNo('%1..%2', WorkDate() - 1, WorkDate()));

        // [WHEN] Run report "Day Book VAT Entry" on these documents.
        REPORT.Run(REPORT::"Day Book VAT Entry");

        // [THEN] "Sell-to/Buy-from Name" values are "CUST", "VEND", "CUST".
        LibraryXMLRead.Initialize(LibraryVariableStorage.DequeueText());
        Assert.AreEqual(Customer.Name, LibraryXMLRead.GetNodeValueAtIndex('SellToBuyFromName', 0), 'Wrond first line');
        Assert.AreEqual(Vendor.Name, LibraryXMLRead.GetNodeValueAtIndex('SellToBuyFromName', 1), 'Wrong second line');
        Assert.AreEqual(Customer.Name, LibraryXMLRead.GetNodeValueAtIndex('SellToBuyFromName', 2), 'Wrong third line');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DayBookCustLedgerEntryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DayBookCustLedgerEntryTaxEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry1: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
    begin
        // [FEATURE] [Sales] [Tax]
        // [SCENARIO 408134] Day Book Cust. Ledger Entry report for Tax Entries

        // [GIVEN] Customer Ledger Entry with VAT Entries
        LibraryVariableStorage.Clear();
        DeleteObjectOptionsIfNeeded();
        CreateCustomerLedgerEntry(CustLedgerEntry, false);

        // [GIVEN] VAT Entries for document with Tax Area has two Tax Jusrisdicions and 2 lines with Amounts = 1000 and 1500.
        // [GIVEN] Entries for "TJ1": 1. "TaxGroup1" with Base1 = 1000, Amount = 2; 2. "TaxGroup2" with Base2 = 1500 Amount = 3;
        // [GIVEN] Entries for "TJ2": 3. "TaxGroup1" with Base1 = 1000, Amount = 6; 4. "TaxGroup2" with Base2 = 1500 Amount = 9;
        CreateVATEntriesWithTaxDetails(
          VATEntry1, VATEntry2, CustLedgerEntry."Transaction No.", VATEntry1.Type::" ",
          LibraryRandom.RandIntInRange(100, 200), LibraryRandom.RandIntInRange(100, 200), CustLedgerEntry."Customer No.");

        // [WHEN] Run Day Book Cust. Ledger Entry report
        REPORT.Run(REPORT::"Day Book Cust. Ledger Entry");  // Opens DayBookCustLedgerEntryRequestPageHandler.

        // [THEN] VAT Amount = 20, VAT Base = 2500 in the report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VATAmountCapTxt, -(VATEntry1.Amount + VATEntry2.Amount));
        LibraryReportDataset.AssertElementWithValueExists(VATBaseCapTxt, -(VATEntry1.Base + VATEntry2.Base));
    end;

    [Test]
    [HandlerFunctions('DayBookVendorLedgerEntryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DayBookVendorLedgerEntryTaxEntries()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry1: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
    begin
        // [FEATURE] [Purchase] [Tax]
        // [SCENARIO 408134] Day Book Vendor Ledger Entry report for Tax Entries

        // [GIVEN] Vendor Ledger Entry with VAT Entries
        LibraryVariableStorage.Clear();
        DeleteObjectOptionsIfNeeded();
        CreateVendorLedgerEntry(VendorLedgerEntry, '', LibraryUTUtility.GetNewCode(), false, 0, VendorLedgerEntry."Document Type"::Invoice);

        // [GIVEN] VAT Entries for document with Tax Area has two Tax Jusrisdicions and 2 lines with Amounts = 1000 and 1500.
        // [GIVEN] Entries for "TJ1": 1. "TaxGroup1" with Base1 = 1000, Amount = 2; 2. "TaxGroup2" with Base2 = 1500 Amount = 3;
        // [GIVEN] Entries for "TJ2": 3. "TaxGroup1" with Base1 = 1000, Amount = 6; 4. "TaxGroup2" with Base2 = 1500 Amount = 9;
        CreateVATEntriesWithTaxDetails(
          VATEntry1, VATEntry2, VendorLedgerEntry."Transaction No.", VATEntry1.Type::" ",
          LibraryRandom.RandIntInRange(100, 200), LibraryRandom.RandIntInRange(100, 200), VendorLedgerEntry."Vendor No.");

        // [WHEN] Run Day Book Vendor Ledger Entry report
        REPORT.Run(REPORT::"Day Book Vendor Ledger Entry");  // Opens DayBookVendorLedgerEntryRequestPageHandler.

        // [THEN] VAT Amount = 20, VAT Base = 2500 in the report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VATAmountCapTxt, -(VATEntry1.Amount + VATEntry2.Amount));
        LibraryReportDataset.AssertElementWithValueExists(VATBaseCapTxt, -(VATEntry1.Base + VATEntry2.Base));
    end;

    local procedure InitReports()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        if isInitialized then
            exit;

        // Setup logo to be printed by default
        SalesSetup.Validate("Logo Position on Documents", SalesSetup."Logo Position on Documents"::Center);
        SalesSetup.Modify(true);

        isInitialized := true;
        Commit();
    end;

    local procedure FomatFileName(ReportCaption: Text) ReportFileName: Text
    begin
        ReportFileName := DelChr(ReportCaption, '=', '/') + '.pdf'
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHDayBookVATEntry(var DayBookVATEntry: TestRequestPage "Day Book VAT Entry")
    begin
        DayBookVATEntry.ReqVATEntry.SetFilter("Posting Date", Format(WorkDate()));
        DayBookVATEntry.SaveAsPdf(FomatFileName(DayBookVATEntry.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHDayBookCustLedgerEntry(var DayBookCustLedgerEntry: TestRequestPage "Day Book Cust. Ledger Entry")
    begin
        DayBookCustLedgerEntry.ReqCustLedgEntry.SetFilter("Posting Date", Format(WorkDate()));
        DayBookCustLedgerEntry.SaveAsPdf(FomatFileName(DayBookCustLedgerEntry.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHDayBookVendorLedgerEntry(var DayBookVendorLedgerEntry: TestRequestPage "Day Book Vendor Ledger Entry")
    begin
        DayBookVendorLedgerEntry.ReqVendLedgEntry.SetFilter("Posting Date", Format(WorkDate()));
        DayBookVendorLedgerEntry.SaveAsPdf(FomatFileName(DayBookVendorLedgerEntry.Caption));
    end;

    local procedure DayBookVATEntryReport(Type: Enum "General Posting Type"; BillToPayToNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        // Setup.
        LibraryVariableStorage.Clear();
        DeleteObjectOptionsIfNeeded();
        CreateVATEntry(VATEntry, 0, Type, LibraryRandom.RandDec(10, 2), '', '', BillToPayToNo);  // Taken random for Base and blank for VATProdPostingGroup and VATBusPostingGroup.
        LibraryVariableStorage.Enqueue(VATEntry."Document No.");  // Enqueue for DayBookVATEntryRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Day Book VAT Entry");

        // Verify.
        VerifyValuesOnReport('VAT_Entry__Base', VATEntryAmountCapTxt, VATEntry.Base, VATEntry.Amount)
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
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

    local procedure CreateCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; PrintCustLedgerDetails: Boolean)
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
    begin
        CreateGLEntry(GLEntry);
        CustLedgerEntry2.FindLast();
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

        // Required inside DayBookCustLedgerEntryRequestPageHandler.
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Customer No.");
        LibraryVariableStorage.Enqueue(PrintCustLedgerDetails);
    end;

    local procedure CreateDetailedCustomerLedgerEntry(CustLedgerEntryNo: Integer; TransactionNo: Integer): Integer
    var
        DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry2.FindLast();
        DetailedCustLedgEntry."Entry No." := DetailedCustLedgEntry2."Entry No." + 1;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntryNo;
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::"Realized Loss";
        DetailedCustLedgEntry."Amount (LCY)" := LibraryRandom.RandDec(10, 2);
        DetailedCustLedgEntry."Transaction No." := TransactionNo;
        DetailedCustLedgEntry.Insert(true);
        exit(DetailedCustLedgEntry."Entry No.");
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AppliesToID: Code[50]; VendorNo: Code[20]; PrintVendLedgerDetails: Boolean; AmountToApply: Decimal; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CreateVendorLedgerEntryWithGLEntry(VendorLedgerEntry, AppliesToID, VendorNo, AmountToApply, DocumentType);
        VendorLedgerEntry."Remaining Pmt. Disc. Possible" := LibraryRandom.RandDec(10, 2); // Using Random value less than Amount.
        VendorLedgerEntry."Pmt. Disc. Rcd.(LCY)" := LibraryRandom.RandDec(10, 2);
        VendorLedgerEntry."Pmt. Discount Date" := WorkDate();
        VendorLedgerEntry.Modify();

        // Required inside DayBookVendorLedgerEntryRequestPageHandler.
        LibraryVariableStorage.Enqueue(VendorLedgerEntry."Vendor No.");
        LibraryVariableStorage.Enqueue(PrintVendLedgerDetails);
    end;

    local procedure CreateDetailedVendorLedgerEntry(VendorLedgerEntryNo: Integer; TransactionNo: Integer): Integer
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntryNo;
        DetailedVendorLedgEntry."Entry Type" := DetailedVendorLedgEntry."Entry Type"::"Realized Loss";
        DetailedVendorLedgEntry.Amount := LibraryRandom.RandDecInDecimalRange(10, 20, 2);  // Using Random value more than Applied value.
        DetailedVendorLedgEntry."Amount (LCY)" := DetailedVendorLedgEntry.Amount;
        DetailedVendorLedgEntry."Transaction No." := TransactionNo;
        DetailedVendorLedgEntry.Insert(true);
        exit(DetailedVendorLedgEntry."Entry No.");
    end;

    local procedure CreateVATEntry(var VATEntry: Record "VAT Entry"; TransactionNo: Integer; Type: Enum "General Posting Type"; Base: Decimal; VATProdPostingSetup: Code[10]; VATBusPostingSetup: Code[10]; BillToPayToNo: Code[20])
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry.Type := Type;
        VATEntry."Transaction No." := TransactionNo;
        VATEntry."Bill-to/Pay-to No." := BillToPayToNo;
        VATEntry."Document No." := LibraryUTUtility.GetNewCode();
        VATEntry."VAT Bus. Posting Group" := VATBusPostingSetup;
        VATEntry."VAT Prod. Posting Group" := VATProdPostingSetup;
        VATEntry.Base := Base;
        VATEntry."VAT Base Discount %" := LibraryRandom.RandDec(10, 2);
        VATEntry."VAT Difference" := LibraryRandom.RandDec(10, 2);
        VATEntry.Amount := LibraryRandom.RandDec(10, 2);
        VATEntry."Posting Date" := WorkDate();
        VATEntry.Insert();
    end;

    local procedure CreateVATEntriesWithTaxDetails(var VATEntry1: Record "VAT Entry"; var VATEntry2: Record "VAT Entry"; TransactionNo: Integer; Type: Enum "General Posting Type"; Base1: Decimal; Base2: Decimal; BillToPayToNo: Code[20])
    var
        TaxAreaCode: Code[20];
        TaxGroupCode1: Code[20];
        TaxGroupCode2: Code[20];
    begin
        TaxAreaCode := LibraryUtility.GenerateGUID();
        TaxGroupCode1 := LibraryUtility.GenerateGUID();
        TaxGroupCode2 := LibraryUtility.GenerateGUID();

        // VAT Entries with Tax Area/ Tax Group/ Tax Jurisdiction:
        // "TJ1": 1. "TG1" with Base1; 2. "TG2" with Base2;
        // "TJ2": 3. "TG1" with Base1; 4. "TG2" with Base2
        CreateVATEntry(VATEntry1, TransactionNo, Type, Base1, '', '', BillToPayToNo);
        UpdateVATEntryWithTaxDetails(VATEntry1, TaxAreaCode, TaxGroupCode1);
        CreateVATEntry(VATEntry2, TransactionNo, Type, Base2, '', '', BillToPayToNo);
        UpdateVATEntryWithTaxDetails(VATEntry2, TaxAreaCode, TaxGroupCode2);
        CreateVATEntry(VATEntry1, TransactionNo, Type, Base1, '', '', BillToPayToNo);
        UpdateVATEntryWithTaxDetails(VATEntry1, TaxAreaCode, TaxGroupCode1);
        CreateVATEntry(VATEntry2, TransactionNo, Type, Base2, '', '', BillToPayToNo);
        UpdateVATEntryWithTaxDetails(VATEntry2, TaxAreaCode, TaxGroupCode2);

        // Calculate Base and Amount per each Tax Group
        VATEntry1.SetRange("Tax Group Code", TaxGroupCode1);
        VATEntry1.FindFirst();
        VATEntry1.CalcSums(Amount);
        VATEntry2.SetRange("Tax Group Code", TaxGroupCode2);
        VATEntry2.FindFirst();
        VATEntry2.CalcSums(Amount);
    end;

    local procedure UpdateVATEntryWithTaxDetails(var VATEntry: Record "VAT Entry"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    begin
        VATEntry."Tax Liable" := true;
        VATEntry."Tax Area Code" := TaxAreaCode;
        VATEntry."Tax Group Code" := TaxGroupCode;
        VATEntry."Tax Jurisdiction Code" := LibraryUTUtility.GetNewCode10();
        VATEntry.Modify();
    end;

    local procedure VerifyValuesOnReport(ElementName: Text; ElementName2: Text; ExpectedValue: Variant; ExpectedValue2: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ElementName, ExpectedValue);
        LibraryReportDataset.AssertElementWithValueExists(ElementName2, ExpectedValue2);
    end;

    local procedure CreateVATAndCustomerPostingSetup(var VATPostingSetup: Record "VAT Posting Setup") CustomerPostingGroupCode: Code[20]
    begin
        CreateVATPostingSetup(VATPostingSetup);
        CustomerPostingGroupCode := CreateCustomerPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
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

    local procedure CreateGLEntry(var GLEntry: Record "G/L Entry")
    var
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry2.FindLast();
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."G/L Account No." := LibraryUTUtility.GetNewCode();
        GLEntry."Document No." := LibraryUTUtility.GetNewCode();
        GLEntry."Transaction No." := SelectGLEntryTransactionNo();
        GLEntry.Insert();
    end;

    local procedure CreateVendorLedgerEntryWithGLEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AppliesToID: Code[50]; VendorNo: Code[20]; AmountToApply: Decimal; DocumentType: Enum "Gen. Journal Document Type")
    var
        GLEntry: Record "G/L Entry";
    begin
        CreateGLEntry(GLEntry);
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Applies-to ID" := AppliesToID;
        VendorLedgerEntry."Amount to Apply" := AmountToApply;
        VendorLedgerEntry."External Document No." := LibraryUTUtility.GetNewCode();
        VendorLedgerEntry."Document Type" := DocumentType;
        VendorLedgerEntry."Transaction No." := GLEntry."Transaction No.";
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry."Closed by Entry No." := VendorLedgerEntry."Entry No.";
        VendorLedgerEntry.Insert();
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

    local procedure SelectGLEntryTransactionNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.FindLast();
        exit(GLEntry."Transaction No." + 1);
    end;

    local procedure CreateVATProductPostingGroup(): Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        VATProductPostingGroup.Insert();
        exit(VATProductPostingGroup.Code);
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

    local procedure CreateGeneralPostingSetup(DefVATProdPostingGroup: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup."Gen. Prod. Posting Group" := CreateGenProductPostingGroup(DefVATProdPostingGroup);
        GeneralPostingSetup.Insert();
        exit(GeneralPostingSetup."Gen. Prod. Posting Group");
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

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]; PostingDate: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, CustomerNo);
        SalesHeader."Posting Date" := PostingDate;
        SalesHeader.Modify();
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure CreateAndPostPurchaseInvoice(VendorNo: Code[20]; PostingDate: Date): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, VendorNo);
        PurchaseHeader."Posting Date" := PostingDate;
        PurchaseHeader.Modify();
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
    end;

    local procedure DeleteObjectOptionsIfNeeded()
    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
    begin
        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DayBookVendorLedgerEntryRequestPageHandler(var DayBookVendorLedgerEntry: TestRequestPage "Day Book Vendor Ledger Entry")
    var
        VendorNo: Variant;
        PrintVendLedgerDetails: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Day Book Vendor Ledger Entry";
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(PrintVendLedgerDetails);
        DayBookVendorLedgerEntry.PrintVendLedgerDetails.SetValue(PrintVendLedgerDetails);
        DayBookVendorLedgerEntry.PrintGLEntryDetails.SetValue(PrintVendLedgerDetails);
        DayBookVendorLedgerEntry.ReqVendLedgEntry.SetFilter("Vendor No.", VendorNo);
        DayBookVendorLedgerEntry.ReqVendLedgEntry.SetFilter("Posting Date", Format(WorkDate()));
        DayBookVendorLedgerEntry.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DayBookCustLedgerEntryRequestPageHandler(var DayBookCustLedgerEntry: TestRequestPage "Day Book Cust. Ledger Entry")
    var
        CustomerNo: Variant;
        PrintCustLedgerDetails: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Day Book Cust. Ledger Entry";
        LibraryVariableStorage.Dequeue(CustomerNo);
        LibraryVariableStorage.Dequeue(PrintCustLedgerDetails);
        DayBookCustLedgerEntry.PrintCustLedgerDetails.SetValue(PrintCustLedgerDetails);
        DayBookCustLedgerEntry.PrintGLEntryDetails.SetValue(PrintCustLedgerDetails);
        DayBookCustLedgerEntry.ReqCustLedgEntry.SetFilter("Customer No.", CustomerNo);
        DayBookCustLedgerEntry.ReqCustLedgEntry.SetFilter("Posting Date", Format(WorkDate()));
        DayBookCustLedgerEntry.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DayBookVATEntryRequestPageHandler(var DayBookVATEntry: TestRequestPage "Day Book VAT Entry")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        DayBookVATEntry.ReqVATEntry.SetFilter("Posting Date", Format(WorkDate()));
        DayBookVATEntry.ReqVATEntry.SetFilter("Document No.", DocumentNo);
        DayBookVATEntry.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DayBookVATEntrySetFiltersRequestPageHandler(var DayBookVATEntry: TestRequestPage "Day Book VAT Entry")
    var
        FileName: Text;
    begin
        DayBookVATEntry.ReqVATEntry.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        DayBookVATEntry.ReqVATEntry.SetFilter("Posting Date", LibraryVariableStorage.DequeueText());
        FileName := LibraryReportDataset.GetFileName();
        DayBookVATEntry.SaveAsXml(LibraryReportDataset.GetParametersFileName(), FileName);
        LibraryVariableStorage.Enqueue(FileName);
    end;
}

