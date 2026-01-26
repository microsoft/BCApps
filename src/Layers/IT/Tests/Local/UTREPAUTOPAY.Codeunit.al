codeunit 144051 "UT REP AUTOPAY"
{
    //  1. Purpose of the test is to validate Issued Customer Bill Header - OnAfterGetRecord Trigger of Report - 12174 Issued Cust Bills Report.
    //  2. Purpose of the test is to validate Cust. Ledger Entry - OnAfterGetRecord Trigger of Report - 12104 Customer Sheet Print without Currency.
    //  3. Purpose of the test is to validate CustLedgEntry1 - OnAfterGetRecord Trigger of Report - 12117 Customer Bills List.
    //  4. Purpose of the test is to validate OnPreReport Trigger of Report - 12116 Vendor Account Bills List for blank Ending Date.
    //  5. Purpose of the test is to validate VendLedgEntry1 - OnAfterGetRecord Trigger of Report - 12116 Vendor Account Bills List.
    //  6. Purpose of the test is to validate Customer Bill Header - OnAfterGetRecord Trigger of Report - 12170 List of Bank Receipts.
    //  7. Purpose of the test is to validate Customer Bill Line - OnAfterGetRecord Trigger of Report - 12170 List of Bank Receipts.
    //  8. Purpose of the test is to validate Vendor Bill Header - OnAfterGetRecord Trigger of Report - 12178 Vendor Bill Report.
    //  9. Purpose of the test is to validate Vendor Bill Line - OnAfterGetRecord Trigger of Report - 12178 Vendor Bill Report.
    // 10. Purpose of the test is to validate Posted Vendor Bill Header - OnAfterGetRecord Trigger without Currency of Report - 12179 Issued Vendor Bill List.
    // 12. Purpose of the test is to validate Posted Vendor Bill Header - OnAfterGetRecord Trigger with Currency of Report - 12179 Issued Vendor Bill List.
    // 
    // Covers Test Cases for WI - 347655
    // ------------------------------------------------------------------------------
    // Test Function Name                                                      TFS ID
    // ------------------------------------------------------------------------------
    // OnAfterGetRecordIssuedCustBillHdrIssuedCustBillsRpt       174223,174225,151839
    // OnAfterGetRecordCustLedgerEntryCustomerSheetPrint                152659,152660
    // OnAfterGetRecordCustLedgEntryOneCustomerBillsList         152810,219777,219778
    // OnPreReportVendorAccountBillsListError                           152809,152764
    // OnAfterGetRecordVendLedgEntryOneVendorAccBillsList               219779,219780
    // 
    // Covers Test Cases for WI - 347483
    // ------------------------------------------------------------------------------
    // Test Function Name                                                      TFS ID
    // ------------------------------------------------------------------------------
    // OnAfterGetRecordCustBillHdrListOfBankReceipts
    // OnAfterGetRecordCustBillLineListOfBankReceipts                         151836
    // OnAfterGetRecordVendorBillHdrVendorBillReport                          151846
    // OnAfterGetRecordVendorBillLineVendorBillReport                         151848
    // 
    // Covers Test Cases for WI - 348537
    // ------------------------------------------------------------------------------
    // Test Function Name                                                      TFS ID
    // ------------------------------------------------------------------------------
    // OnAfterGetRecPstdVendBillHdrWithLCYIssuedVendBillList
    // OnAfterGetRecPstdVendBillHdrWithFCYIssuedVendBillList

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        BalanceDueCap: Label 'BalanceDue';
        CurrencyCodeCap: Label 'CurrencyCode';
        CustomerNoCap: Label 'No_Customer';
        DialogErr: Label 'Dialog';
        CustBillHeaderNoCap: Label 'No_CustBillHdr';
        VendBillHeaderNoCap: Label 'No_VendBillHdr';
        OriginalAmountCap: Label 'OrigAmount';
        PostedVendBillHdrNoCap: Label 'No_PostedVendBillHdr';
        RemainingAmountCap: Label 'RemainingAmountLCY';
        TestReportCap: Label 'TestReportText';
        LibraryRandom: Codeunit "Library - Random";
        VendorBillAmountCap: Label 'VendorBillAmnt';
        VendorABICABCap: Label '%1/%2', Comment = '%1 = Vendor Bank Account ABI, %2 = Vendor Bank Account CAB';
        VendABICABCap: Label 'VendABICAB';
        VendInfoOneCap: Label 'VendInfo1';
        VendInfoTwoCap: Label 'VendInfo2';

    [Test]
    [HandlerFunctions('IssuedCustBillsReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordIssuedCustBillHdrIssuedCustBillsRpt()
    var
        IssuedBillNo: Code[20];
    begin
        // Purpose of the test is to validate Issued Customer Bill Header - OnAfterGetRecord Trigger of Report - 12174 Issued Cust Bills Report.

        // Setup.
        Initialize();
        IssuedBillNo := CreateIssuedCustomerBill();
        LibraryVariableStorage.Enqueue(IssuedBillNo);  // Enqueue value for IssuedCustBillsReportRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Issued Cust Bills Report");

        // Verify: Verify TestReportText on XML of Report - 12174 Issued Cust Bills Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TestReportCap, Format(IssuedBillNo));
    end;

    [Test]
    [HandlerFunctions('CustomerSheetPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustLedgerEntryCustomerSheetPrint()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Purpose of the test is to validate Cust. Ledger Entry - OnAfterGetRecord Trigger of Report - 12104 Customer Sheet Print without Currency.

        // Setup.
        Initialize();
        CreateCustomerLedgerEntry(CustLedgerEntry);
        CreateDetailedCustomerLedgerEntry(CustLedgerEntry);
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Customer No.");  // Enqueue value for CustomerSheetPrintRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Customer Sheet - Print");

        // Verify: Verify values on XML of Report - 12104 Customer Sheet Print.
        // CurrencyCode and OrigAmount must be blank.
        VerifyValuesOnXML(CustomerNoCap, CurrencyCodeCap, CustLedgerEntry."Customer No.", '');  // Blank for Currency code.
        LibraryReportDataset.AssertElementWithValueExists(OriginalAmountCap, '');
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustLedgEntryOneCustomerBillsList()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Purpose of the test is to validate CustLedgEntry1 - OnAfterGetRecord Trigger of Report - 12117 Customer Bills List.

        // Setup.
        Initialize();
        CreateCustomerLedgerEntry(CustLedgerEntry);
        CreateDetailedCustomerLedgerEntry(CustLedgerEntry);
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Customer No.");  // Enqueue value for CustomerBillsListRequestPageHandler.
        CustLedgerEntry.CalcFields("Remaining Amt. (LCY)");

        // Exercise.
        REPORT.Run(REPORT::"Customer Bills List");

        // Verify: Verify values on XML of Report - 12117 Customer Bills List.
        VerifyValuesOnXML(
          BalanceDueCap, RemainingAmountCap, CustLedgerEntry."Remaining Amt. (LCY)", CustLedgerEntry."Remaining Amt. (LCY)");
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportVendorAccountBillsListError()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report - 12116 Vendor Account Bills List for blank Ending Date.

        // Setup.
        Initialize();
        EnqueueValuesForVendorAccountBillsListRequestPageHandler('', 0D);  // Enqueue blank as Vendor No.,0D as Ending Date for VendorAccountBillsListRequestPageHandler.

        // Exercise.
        asserterror REPORT.Run(REPORT::"Vendor Account Bills List");

        // Verify: Verify expected error code,actual error: "Please specify the Ending Date.".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendLedgEntryOneVendorAccBillsList()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AmountToPay: Decimal;
    begin
        // Purpose of the test is to validate VendLedgEntry1 - OnAfterGetRecord Trigger of Report - 12116 Vendor Account Bills List.

        // Setup.
        Initialize();
        AmountToPay := LibraryRandom.RandDec(100, 2);
        CreateVendorLedgerEntry(VendorLedgerEntry, AmountToPay);
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry);
        EnqueueValuesForVendorAccountBillsListRequestPageHandler(VendorLedgerEntry."Vendor No.", WorkDate());  // Enqueue WORKDATE as Ending Date for VendorAccountBillsListRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Vendor Account Bills List");

        // Verify: Verify VendorBillAmnt on XML of Report - 12116 Vendor Account Bills List.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VendorBillAmountCap, AmountToPay);
    end;

    [Test]
    [HandlerFunctions('ListOfBankReceiptsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustBillHdrListOfBankReceipts()
    begin
        // Purpose of the test is to validate Customer Bill Header - OnAfterGetRecord Trigger of Report - 12170 List of Bank Receipts.
        ListOfBankReceipts(false, true);  // False for Cumulative Bank Receipts and True for Test Report.
    end;

    [Test]
    [HandlerFunctions('ListOfBankReceiptsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustBillLineListOfBankReceipts()
    begin
        // Purpose of the test is to validate Customer Bill Line - OnAfterGetRecord Trigger of Report - 12170 List of Bank Receipts.
        ListOfBankReceipts(true, false);  // True for Cumulative Bank Receipts and False for Test Report.
    end;

    local procedure ListOfBankReceipts(CumulativeBankReceipts: Boolean; TestReport: Boolean)
    var
        CustomerBillNo: Code[20];
    begin
        // Setup.
        Initialize();
        CustomerBillNo := CreateCustomerBill(CumulativeBankReceipts, TestReport);
        LibraryVariableStorage.Enqueue(CustomerBillNo);  // Enqueue value for ListOfBankReceiptsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"List of Bank Receipts");

        // Verify: Verify No_CustBillHdr on XML of Report - 12170 List of Bank Receipts.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CustBillHeaderNoCap, CustomerBillNo);
    end;

    [Test]
    [HandlerFunctions('VendorBillReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorBillHdrVendorBillReport()
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate Vendor Bill Header - OnAfterGetRecord Trigger of Report - 12178 Vendor Bill Report.
        VendorBillReport('', VendorBillHeader."List Status"::Sent);  // Blank for Currency Code.
    end;

    [Test]
    [HandlerFunctions('VendorBillReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorBillLineVendorBillReport()
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate Vendor Bill Line - OnAfterGetRecord Trigger of Report - 12178 Vendor Bill Report.
        VendorBillReport(LibraryUTUtility.GetNewCode10(), VendorBillHeader."List Status"::Open);
    end;

    local procedure VendorBillReport(CurrencyCode: Code[10]; ListStatus: Option)
    var
        VendorBillNo: Code[20];
    begin
        // Setup.
        Initialize();
        VendorBillNo := CreateVendorBill(CurrencyCode, ListStatus, 0, 0);  // 0 for VendorEntryNo and AmountToPay.
        LibraryVariableStorage.Enqueue(VendorBillNo);  // Enqueue value for VendorBillReportRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Vendor Bill Report");

        // Verify: Verify No_VendBillHdr on XML of Report - 12178 Vendor Bill Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VendBillHeaderNoCap, VendorBillNo);
    end;

    [Test]
    [HandlerFunctions('IssuedVendorBillListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecPstdVendBillHdrWithLCYIssuedVendBillList()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Purpose of the test is to validate Posted Vendor Bill Header - OnAfterGetRecord Trigger without Currency of Report - 12179 Issued Vendor Bill List.
        Initialize();
        GeneralLedgerSetup.Get();
        OnAfterGetRecPstdVendBillHdrIssuedVendBillList('', GeneralLedgerSetup."LCY Code");  // Blank for Currency code.
    end;

    [Test]
    [HandlerFunctions('IssuedVendorBillListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecPstdVendBillHdrWithFCYIssuedVendBillList()
    var
        CurrencyCode: Code[10];
    begin
        // Purpose of the test is to validate Posted Vendor Bill Header - OnAfterGetRecord Trigger with Currency of Report - 12179 Issued Vendor Bill List.
        Initialize();
        CurrencyCode := LibraryUTUtility.GetNewCode10();
        OnAfterGetRecPstdVendBillHdrIssuedVendBillList(CurrencyCode, CurrencyCode);
    end;

    local procedure OnAfterGetRecPstdVendBillHdrIssuedVendBillList(CurrencyCode: Code[10]; ExpectedCurrencyCode: Code[10])
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        PostedVendorBillHeaderNo: Code[20];
    begin
        // Setup: Create Vendor Bank Account and Posted Vendor Bill.
        Vendor.Get(CreateVendor());
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        PostedVendorBillHeaderNo := CreatePostedVendorBill(CurrencyCode, Vendor."No.", VendorBankAccount.Code);
        LibraryVariableStorage.Enqueue(PostedVendorBillHeaderNo);  // Enqueue for IssuedVendorBillListRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Issued Vendor Bill List");  // Invokes IssuedVendorBillListRequestPageHandler.

        // Verify: Verify values on XML of Report - 12179 Issued Vendor Bill List.
        VerifyValuesOnXML(PostedVendBillHdrNoCap, CurrencyCodeCap, PostedVendorBillHeaderNo, ExpectedCurrencyCode);
        LibraryReportDataset.AssertElementWithValueExists(
          VendABICABCap, StrSubstNo(VendorABICABCap, VendorBankAccount.ABI, VendorBankAccount.CAB));
        LibraryReportDataset.AssertElementWithValueExists(VendInfoOneCap, Vendor.Name);
        LibraryReportDataset.AssertElementWithValueExists(VendInfoTwoCap, Vendor.Address);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount.ABI := CopyStr(LibraryUTUtility.GetNewCode10(), 1, 5);
        BankAccount.CAB := CopyStr(LibraryUTUtility.GetNewCode10(), 1, 5);
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateCustomerBill(CumulativeBankReceipts: Boolean; TestReport: Boolean): Code[20]
    var
        CustomerBillHeader: Record "Customer Bill Header";
        CustomerBillLine: Record "Customer Bill Line";
    begin
        CustomerBillHeader."No." := LibraryUTUtility.GetNewCode();
        CustomerBillHeader."Bank Account No." := CreateBankAccount();
        CustomerBillHeader."Test Report" := TestReport;
        CustomerBillHeader.Insert();
        CustomerBillLine."Customer Bill No." := CustomerBillHeader."No.";
        CustomerBillLine."Customer No." := CreateCustomer();
        CustomerBillLine."Cumulative Bank Receipts" := CumulativeBankReceipts;
        CustomerBillLine.Insert();
        exit(CustomerBillHeader."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateDetailedCustomerLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry."Customer No." := CustLedgerEntry."Customer No.";
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
        DetailedCustLedgEntry."Amount (LCY)" := CustLedgerEntry."Amount (LCY)";
        DetailedCustLedgEntry."Posting Date" := CustLedgerEntry."Posting Date";
        DetailedCustLedgEntry.Insert(true);
    end;

    local procedure CreateCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry2.FindLast();
        CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Customer No." := CreateCustomer();
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Amount (LCY)" := LibraryRandom.RandDec(10, 2);
        CustLedgerEntry."Due Date" := CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'M>', WorkDate());  // Using earlier date than WORKDATE as Due Date must be earlier than Ending Date.
        CustLedgerEntry.Insert();
    end;

    local procedure CreateIssuedCustomerBill(): Code[20]
    var
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        IssuedCustomerBillLine: Record "Issued Customer Bill Line";
    begin
        IssuedCustomerBillHeader."No." := LibraryUTUtility.GetNewCode();
        IssuedCustomerBillHeader."Bank Account No." := CreateBankAccount();
        IssuedCustomerBillHeader.Insert();
        IssuedCustomerBillLine."Customer Bill No." := IssuedCustomerBillHeader."No.";
        IssuedCustomerBillLine."Customer No." := CreateCustomer();
        IssuedCustomerBillLine.Insert();
        exit(IssuedCustomerBillHeader."No.");
    end;

    local procedure CreatePostedVendorBill(CurrencyCode: Code[10]; VendorNo: Code[20]; VendorBankAccountNo: Code[20]): Code[20]
    var
        PostedVendorBillHeader: Record "Posted Vendor Bill Header";
        PostedVendorBillLine: Record "Posted Vendor Bill Line";
    begin
        PostedVendorBillHeader."No." := LibraryUTUtility.GetNewCode();
        PostedVendorBillHeader."Bank Account No." := CreateBankAccount();
        PostedVendorBillHeader."Currency Code" := CurrencyCode;
        PostedVendorBillHeader.Insert();
        PostedVendorBillLine."Vendor Bill No." := PostedVendorBillHeader."No.";
        PostedVendorBillLine."Vendor No." := VendorNo;
        PostedVendorBillLine."Vendor Bank Acc. No." := VendorBankAccountNo;
        PostedVendorBillLine.Insert();
        exit(PostedVendorBillHeader."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Name := LibraryUTUtility.GetNewCode();
        Vendor.Address := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; VendorNo: Code[20])
    begin
        VendorBankAccount.Code := LibraryUTUtility.GetNewCode10();
        VendorBankAccount."Vendor No." := VendorNo;
        VendorBankAccount.ABI := CopyStr(LibraryUTUtility.GetNewCode10(), 1, 5);
        VendorBankAccount.CAB := CopyStr(LibraryUTUtility.GetNewCode10(), 1, 5);
        VendorBankAccount.Insert();
    end;

    local procedure CreateVendorBill(CurrencyCode: Code[10]; ListStatus: Option; EntryNo: Integer; AmountToPay: Decimal): Code[20]
    var
        VendorBillLine: Record "Vendor Bill Line";
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBankAccount: Record "Vendor Bank Account";
        VendorNo: Code[20];
    begin
        VendorNo := CreateVendor();
        CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBillHeader."No." := LibraryUTUtility.GetNewCode();
        VendorBillHeader."Currency Code" := CurrencyCode;
        VendorBillHeader."List Status" := ListStatus;
        VendorBillHeader."Bank Account No." := CreateBankAccount();
        VendorBillHeader.Insert();
        VendorBillLine."Vendor No." := VendorNo;
        VendorBillLine."Vendor Bank Acc. No." := VendorBankAccount.Code;
        VendorBillLine."Vendor Bill List No." := VendorBillHeader."No.";
        VendorBillLine."Vendor Bill No." := VendorBillHeader."No.";
        VendorBillLine."Vendor Entry No." := EntryNo;
        VendorBillLine."Amount to Pay" := AmountToPay;
        VendorBillLine.Insert();
        exit(VendorBillHeader."No.");
    end;

    local procedure CreateDetailedVendorLedgerEntry(VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry."Vendor No." := VendorLedgerEntry."Vendor No.";
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        DetailedVendorLedgEntry."Posting Date" := VendorLedgerEntry."Posting Date";
        DetailedVendorLedgEntry.Insert(true);
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AmountToPay: Decimal)
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        VendorLedgerEntry2.FindLast();
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Vendor No." := CreateVendor();
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Vendor Bill No." :=
          CreateVendorBill('', VendorBillHeader."List Status"::Open, VendorLedgerEntry."Entry No.", AmountToPay);  // Blank value for CurrencyCode.
        VendorLedgerEntry.Insert();
    end;

    local procedure EnqueueValuesForVendorAccountBillsListRequestPageHandler(VendorNo: Code[20]; EndingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(EndingDate);
    end;

    local procedure VerifyValuesOnXML(Caption: Text; Caption2: Text; Value: Variant; Value2: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Caption, Value);
        LibraryReportDataset.AssertElementWithValueExists(Caption2, Value2);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerBillsListRequestPageHandler(var CustomerBillsList: TestRequestPage "Customer Bills List")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CustomerBillsList."Ending Date".SetValue(WorkDate());
        CustomerBillsList.Customer.SetFilter("No.", No);
        CustomerBillsList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerSheetPrintRequestPageHandler(var CustomerSheetPrint: TestRequestPage "Customer Sheet - Print")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CustomerSheetPrint.Customer.SetFilter("No.", No);
        CustomerSheetPrint.Customer.SetFilter("Date Filter", Format(WorkDate()));
        CustomerSheetPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IssuedCustBillsReportRequestPageHandler(var IssuedCustBillsReport: TestRequestPage "Issued Cust Bills Report")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        IssuedCustBillsReport."Issued Customer Bill Header".SetFilter("No.", No);
        IssuedCustBillsReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IssuedVendorBillListRequestPageHandler(var IssuedVendorBillList: TestRequestPage "Issued Vendor Bill List")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        IssuedVendorBillList."Posted Vendor Bill Header".SetFilter("No.", No);
        IssuedVendorBillList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ListOfBankReceiptsRequestPageHandler(var ListOfBankReceipts: TestRequestPage "List of Bank Receipts")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ListOfBankReceipts."Customer Bill Header".SetFilter("No.", No);
        ListOfBankReceipts.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListRequestPageHandler(var VendorAccountBillsList: TestRequestPage "Vendor Account Bills List")
    var
        No: Variant;
        EndingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(EndingDate);
        VendorAccountBillsList.Vendor.SetFilter("No.", No);
        VendorAccountBillsList.EndingDate.SetValue(EndingDate);
        VendorAccountBillsList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorBillReportRequestPageHandler(var VendorBillReport: TestRequestPage "Vendor Bill Report")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        VendorBillReport."Vendor Bill Header".SetFilter("No.", No);
        VendorBillReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

