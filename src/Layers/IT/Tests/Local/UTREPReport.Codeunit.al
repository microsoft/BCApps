codeunit 144149 "UT REP Report"
{
    // // [FEATURE] [UT][Report]
    // 1. Purpose of the test is to verify On Pre Report Trigger of LIFO Band for Report ID 12123 - LIFO Entries.
    // 2. Purpose of the test is to verify On After Get Record Trigger of LIFO Band for Report ID 12123 - LIFO Entries.
    // 4. Purpose of the test is to verify On Pre Report Trigger of LIFO Band for Report ID 12137 - LIFO Valuation.
    // 5. Purpose of the test is to verify On Pre Data Item Trigger of Date for Report ID 12182 - VAT Plafond Period.
    // 6. Purpose of the test is to verify On After Get Record Trigger of Posted Vendor Bill Header with currency of Report ID 12179 - Issued Vendor Bill List report.
    // 7. Purpose of the test is to verify On After Get Record Trigger of Posted Vendor Bill Header without currency of Report ID 12179 - Issued Vendor Bill List report.
    // 
    // Covers Test Cases for WI - 345127
    // -----------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                       TFS ID
    // -----------------------------------------------------------------------------------------------------------------
    // OnPreReportLIFOBandLIFOEntries                                                                           278637
    // OnAfterGetRecordLIFOBandLIFOEntries                                                                      278637
    // OnPreReportLIFOBandLIFOValuation                                                                         280477
    // OnPreDataItemDateVATPlafondPeriod                                                                        278123
    // OnAfterGetRecordPstdVendBillHdrWithCurrIssuedVendBillList                                                278096
    // OnAfterGetRecordPstdVendBillHdrWithoutCurrIssuedVendBillList                                             278096

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        NotDefMsgCap: Label 'NotDefMsg';
        LIFOBandsMsg: Label 'Warning: Not all LIFO Bands are final, the current report is a draft.';
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        DetailedCustLedgEntryEntryNoTok: Label 'Detailed_Cust__Ledg__Entry_Entry_No_';
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('LIFOEntriesReqPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportLIFOBandLIFOEntries()
    begin
        // Purpose of the test is to verify On Pre Report Trigger of LIFO Band for Report ID 12123 - LIFO Entries.
        Initialize();
        LIFOBandLIFOEntries(StrSubstNo(LIFOBandsMsg), NotDefMsgCap, 0);  // Using 0 for Increment value.
    end;

    [Test]
    [HandlerFunctions('LIFOEntriesReqPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordLIFOBandLIFOEntries()
    var
        IncrementValue: Decimal;
    begin
        // Purpose of the test is to verify On After Get Record Trigger of LIFO Band for Report ID 12123 - LIFO Entries.
        Initialize();
        IncrementValue := LibraryRandom.RandDec(100, 2);
        LIFOBandLIFOEntries(IncrementValue, 'InventoryValue', IncrementValue);
    end;

    local procedure LIFOBandLIFOEntries(Value: Variant; Caption: Text; IncrementValue: Decimal)
    begin
        // Setup and Exercise.
        CreateLIFOBandAndRunLIFOEntriesReport(IncrementValue);

        // Verify: Verify value on XML after running report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Caption, Value);
    end;

    [Test]
    [HandlerFunctions('LIFOValuationReqPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportLIFOValuation()
    var
        LifoBand: Record "Lifo Band";
    begin
        // Purpose of the test is to verify On Pre Report Trigger of LIFO Band for Report ID 12137 - LIFO Valuation.

        // Setup.
        Initialize();
        CreateLIFOBand(LifoBand, 0);  // Using 0 for increment value.

        // Exercise.
        REPORT.Run(REPORT::"LIFO Valuation");  // Invokes handler LIFOValuationReqPageHandler.

        // Verify: Verify values on XML after running report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(NotDefMsgCap, StrSubstNo(LIFOBandsMsg));
        LibraryReportDataset.AssertElementWithValueExists('ItemNo', LifoBand."Item No.");
        LibraryReportDataset.AssertElementWithValueExists('OldItem', LifoBand."Item No.");
    end;

    [Test]
    [HandlerFunctions('VATPlafondPeriodReqPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemDateVATPlafondPeriod()
    var
        VATPlafondPeriod: Record "VAT Plafond Period";
    begin
        // Purpose of the test is to verify On Pre Data Item Trigger of Date for Report ID 12182 - VAT Plafond Period.

        // Setup.
        Initialize();
        CreateVATPlafondPeriod(VATPlafondPeriod);

        // Exercise.
        REPORT.Run(REPORT::"VAT Plafond Period");  // Invokes handler VATPlafondPeriodReqPageHandler.

        // Verify: Verify values on XML after running report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Year_VATPlafondPeriod', VATPlafondPeriod.Year);
        LibraryReportDataset.AssertElementWithValueExists('Amt_VATPlafondPeriod', VATPlafondPeriod.Amount);
    end;

    [Test]
    [HandlerFunctions('IssuedVendorBillListReqPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPstdVendBillHdrWithCurrIssuedVendBillList()
    var
        CurrencyCode: Code[10];
    begin
        // Purpose of the test is to verify On After Get Record Trigger of Posted Vendor Bill Header with currency of Report ID 12179 - Issued Vendor Bill List report.
        Initialize();
        CurrencyCode := LibraryUTUtility.GetNewCode10();
        IssuedVendBillListReport(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('IssuedVendorBillListReqPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPstdVendBillHdrWithoutCurrIssuedVendBillList()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Purpose of the test is to verify On After Get Record Trigger of Posted Vendor Bill Header without currency of Report ID 12179 - Issued Vendor Bill List report.
        Initialize();
        GeneralLedgerSetup.Get();
        IssuedVendBillListReport('', GeneralLedgerSetup."LCY Code");  // Using blank for currency code.
    end;

    local procedure IssuedVendBillListReport(CurrencyCode: Code[10]; ExpectedCurrencyCode: Code[10])
    var
        PostedVendorBillLine: Record "Posted Vendor Bill Line";
    begin
        // Setup.
        CreatePostedVendorBill(PostedVendorBillLine, CurrencyCode);
        LibraryVariableStorage.Enqueue(PostedVendorBillLine."Vendor Bill No.");  // Enqueue for IssuedVendorBillListReqPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Issued Vendor Bill List");  // Invokes handler IssuedVendorBillListReqPageHandler.

        // Verify: Verify values on XML after running the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_PostedVendBillHdr', PostedVendorBillLine."Vendor Bill No.");
        LibraryReportDataset.AssertElementWithValueExists('CurrencyCode', ExpectedCurrencyCode);
        LibraryReportDataset.AssertElementWithValueExists(
          'VendBankAccNo_PostedVendBillLine', PostedVendorBillLine."Vendor Bank Acc. No.");
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsListDtldCustLedgEntry()
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        TransactionNo: Integer;
        CustLedgerEntryNo: Integer;
        DetailedCustLedgEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [Customer][Customer Bills List]
        // [SCENARIO 382091] Customer Bills List doesn't have to contain Dtld Cust. Ledger Entry of closed bank receipts
        Initialize();

        // [GIVEN] "Cust. Ledger Entry" with Customer = "C", "Document Type" = Invoice
        CustomerNo := LibrarySales.CreateCustomerNo();
        TransactionNo := LibraryRandom.RandIntInRange(1, 100);
        CustLedgerEntryNo := MockCustLedgerEntry(TransactionNo, CustomerNo, DummyCustLedgerEntry."Document Type"::Invoice);

        // [GIVEN] "Detailed Cust. Ledg. Entry" with "Bank Receipt" = FALSE, "Bank Receipt Issued" = FALSE
        MockDetailedCustLedgEntry(TransactionNo, CustomerNo, CustLedgerEntryNo, false, false);

        // [GIVEN] "Cust. Ledger Entry with Customer = "C", "Document Type" = Payment
        CustLedgerEntryNo := MockCustLedgerEntry(TransactionNo, CustomerNo, DummyCustLedgerEntry."Document Type"::Payment);

        // [GIVEN] First "Detailed Cust. Ledg. Entry" with "Bank Receipt" = FALSE, "Bank Receipt Issued" = FALSE
        DetailedCustLedgEntryNo[1] := MockDetailedCustLedgEntry(TransactionNo, CustomerNo, CustLedgerEntryNo, false, false);
        // [GIVEN] Second "Detailed Cust. Ledg. Entry" with "Bank Receipt" = TRUE, "Bank Receipt Issued" = TRUE
        DetailedCustLedgEntryNo[2] := MockDetailedCustLedgEntry(TransactionNo, CustomerNo, CustLedgerEntryNo, true, true);
        Commit();

        // [WHEN] Run Customer Bills List report for Customer "C"
        RunCustomerBillsListReport(CustomerNo);

        // [THEN] Report contains first "Detailed Cust. Ledg. Entry"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(DetailedCustLedgEntryEntryNoTok, DetailedCustLedgEntryNo[1]);

        // [THEN] Report doesn't contain second "Detailed Cust. Ledg. Entry"
        LibraryReportDataset.AssertElementWithValueNotExist(DetailedCustLedgEntryEntryNoTok, DetailedCustLedgEntryNo[2]);
    end;

    [Test]
    [HandlerFunctions('ListOfBankReceiptsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ListOfBankReceiptsWithCumulativeBankReceipts()
    var
        Customer: Record Customer;
        CustomerBillHeader: Record "Customer Bill Header";
        PaymentMethod: Record "Payment Method";
        ListOfBankReceiptsReport: Report "List of Bank Receipts";
    begin
        // [FEATURE] [Report] [Receipt]
        // [SCENARIO 288116] List of Bank Receipts report shows all Cumulative Bank Receipts
        Initialize();

        // [GIVEN] Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] A Payment Method with Bill Code
        LibraryERM.CreatePaymentMethodWithBalAccount(PaymentMethod);
        PaymentMethod."Bill Code" := PaymentMethod.Code;
        PaymentMethod.Modify();

        // [GIVEN] Customer Bill Header for this Customer
        LibrarySales.CreateCustomerBillHeader(
          CustomerBillHeader, LibraryERM.CreateBankAccountNo(), PaymentMethod.Code, CustomerBillHeader.Type::"Bills Subject To Collection");

        // [GIVEN] 2 lines for Customer with same Due Date = "Date1" with Cumulative Bank Receipts = True
        CreateCustomerBillLine(CustomerBillHeader, Customer, LibraryRandom.RandDec(500, 2), WorkDate(), true);
        CreateCustomerBillLine(CustomerBillHeader, Customer, LibraryRandom.RandDec(500, 2), WorkDate(), true);

        // [GIVEN] 2 lines for Customer with same Due Date = "Date2" with Cumulative Bank Receipts = True
        CreateCustomerBillLine(CustomerBillHeader, Customer, LibraryRandom.RandDec(500, 2), WorkDate() + 1, true);
        CreateCustomerBillLine(CustomerBillHeader, Customer, LibraryRandom.RandDec(500, 2), WorkDate() + 1, true);

        Commit();

        // [WHEN] List of Bank Receipts report is run
        ListOfBankReceiptsReport.SetTableView(CustomerBillHeader);
        LibraryVariableStorage.Enqueue(CustomerBillHeader."No.");
        ListOfBankReceiptsReport.RunModal();
        // RequestPage handled by ListOfBankReceiptsRequestPageHandler

        // [THEN] There are 4 lines with "IsFooter" = true in DataSet
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('IsFooter', 'true');
        Assert.AreEqual(4, LibraryReportDataset.RowCount(), 'Wrong footer row count');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode10();
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item.Insert();
        exit(Item."No.");
    end;

    local procedure CreateLIFOBandAndRunLIFOEntriesReport(IncrementValue: Decimal)
    var
        LifoBand: Record "Lifo Band";
    begin
        // Setup.
        CreateLIFOBand(LifoBand, IncrementValue);

        // Exercise.
        REPORT.Run(REPORT::"Lifo Entries");  // Invokes handler LIFOEntriesReqPageHandler.
    end;

    local procedure CreateLIFOBand(var LifoBand: Record "Lifo Band"; IncrementValue: Decimal)
    begin
        LifoBand.Definitive := false;
        LifoBand.Positive := true;
        LifoBand."Competence Year" := WorkDate();
        LifoBand."Item No." := CreateItem();
        LifoBand."Increment Value" := IncrementValue;
        LifoBand."Residual Quantity" := LibraryRandom.RandDec(100, 2);
        LifoBand.Insert();
    end;

    local procedure CreatePostedVendorBill(var PostedVendorBillLine: Record "Posted Vendor Bill Line"; CurrencyCode: Code[10])
    var
        PostedVendorBillHeader: Record "Posted Vendor Bill Header";
    begin
        PostedVendorBillHeader."No." := LibraryUTUtility.GetNewCode();
        PostedVendorBillHeader."Bank Account No." := CreateBankAccount();
        PostedVendorBillHeader."Currency Code" := CurrencyCode;
        PostedVendorBillHeader.Insert();
        PostedVendorBillLine."Vendor Bill No." := PostedVendorBillHeader."No.";
        PostedVendorBillLine."Vendor No." := CreateVendor();
        PostedVendorBillLine."Vendor Bank Acc. No." := PostedVendorBillHeader."Bank Account No.";
        PostedVendorBillLine.Insert();
    end;

    local procedure CreateVATPlafondPeriod(var VATPlafondPeriod: Record "VAT Plafond Period")
    begin
        VATPlafondPeriod.Year := Date2DMY(WorkDate(), 3);
        VATPlafondPeriod.Amount := LibraryRandom.RandDec(100, 2);
        VATPlafondPeriod.Insert();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateCustomerBillLine(CustomerBillHeader: Record "Customer Bill Header"; Customer: Record Customer; LineAmount: Decimal; DueDate: Date; CumulativeBankReceipts: Boolean)
    var
        CustomerBillLine: Record "Customer Bill Line";
        NewLineNo: Integer;
    begin
        if CustomerBillLine.FindLast() then
            NewLineNo := CustomerBillLine."Line No." + 10000
        else
            NewLineNo := 10000;
        CustomerBillLine.Init();
        CustomerBillLine."Customer No." := Customer."No.";
        CustomerBillLine."Customer Bill No." := CustomerBillHeader."No.";
        CustomerBillLine."Line No." := NewLineNo;
        CustomerBillLine.Amount := LineAmount;
        CustomerBillLine."Due Date" := DueDate;
        CustomerBillLine."Cumulative Bank Receipts" := CumulativeBankReceipts;
        CustomerBillLine."Customer Bank Acc. No." := CustomerBillHeader."Bank Account No.";
        CustomerBillLine.Insert();
    end;

    local procedure MockCustLedgerEntry(TransactionNo: Integer; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        RecRef: RecordRef;
    begin
        CustLedgerEntry.Init();
        RecRef.GetTable(CustLedgerEntry);
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Transaction No." := TransactionNo;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Document No." :=
          LibraryUtility.GenerateRandomCode(CustLedgerEntry.FieldNo("Document No."), DATABASE::"Cust. Ledger Entry");
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Due Date" := WorkDate();
        CustLedgerEntry."Document Type" := DocumentType;
        CustLedgerEntry.Insert();
        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure MockDetailedCustLedgEntry(TransactionNo: Integer; CustomerNo: Code[20]; CustLedgerEntryNo: Integer; BankReceipt: Boolean; BankReceiptIssued: Boolean): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        RecRef: RecordRef;
    begin
        DetailedCustLedgEntry.Init();
        RecRef.GetTable(DetailedCustLedgEntry);
        DetailedCustLedgEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Customer No." := CustomerNo;
        DetailedCustLedgEntry."Document Type" := DetailedCustLedgEntry."Document Type"::Payment;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntryNo;
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::Application;
        DetailedCustLedgEntry."Transaction No." := TransactionNo;
        DetailedCustLedgEntry."Posting Date" := WorkDate();
        DetailedCustLedgEntry."Bank Receipt" := BankReceipt;
        DetailedCustLedgEntry."Bank Receipt Issued" := BankReceiptIssued;
        DetailedCustLedgEntry.Insert();
        exit(DetailedCustLedgEntry."Entry No.");
    end;

    local procedure RunCustomerBillsListReport(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        CustomerBillsList: Report "Customer Bills List";
    begin
        Customer.SetRange("No.", CustomerNo);
        CustomerBillsList.SetTableView(Customer);
        CustomerBillsList.UseRequestPage(true);
        CustomerBillsList.Run();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IssuedVendorBillListReqPageHandler(var IssuedVendorBillListReport: TestRequestPage "Issued Vendor Bill List")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        IssuedVendorBillListReport."Posted Vendor Bill Header".SetFilter("No.", No);
        IssuedVendorBillListReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LIFOEntriesReqPageHandler(var LifoEntries: TestRequestPage "Lifo Entries")
    begin
        LifoEntries."Lifo Band".SetFilter("Competence Year", Format(WorkDate()));
        LifoEntries.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LIFOValuationReqPageHandler(var LifoValuation: TestRequestPage "LIFO Valuation")
    begin
        LifoValuation."Lifo Band".SetFilter("Competence Year", Format(WorkDate()));
        LifoValuation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATPlafondPeriodReqPageHandler(var VATPlafondPeriod: TestRequestPage "VAT Plafond Period")
    begin
        VATPlafondPeriod.VATPlafondPeriod.SetFilter(Year, Format(Date2DMY(WorkDate(), 3)));
        VATPlafondPeriod.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerBillsListRequestPageHandler(var CustomerBillsList: TestRequestPage "Customer Bills List")
    begin
        CustomerBillsList."Ending Date".SetValue(LibraryRandom.RandDate(10));
        CustomerBillsList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ListOfBankReceiptsRequestPageHandler(var ListOfBankReceipts: TestRequestPage "List of Bank Receipts")
    begin
        ListOfBankReceipts."Customer Bill Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        ListOfBankReceipts.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

