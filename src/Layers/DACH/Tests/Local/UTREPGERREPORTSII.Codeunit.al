codeunit 142071 "UT REP GERREPORTS - II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        AdjustmentCap: Label 'AdjustText';
        LibraryRandom: Codeunit "Library - Random";
        AdjustmentValueTxt: Label 'No Exch. Rate Differences Adjustment%1 Debit and credit amounts are not adjusted by real. losses and gains';
        PeriodCreditAmountCap: Label 'PeriodCreditAmount';

    [Test]
    [HandlerFunctions('CustomerTotalBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportCustomerTotalBalanceError()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 11003 - Customer Total-Balance.
        // Setup.
        Initialize();
        CreateCustomer();
        AccountingPeriod.FindLast();

        // Enqueue Accounting Period - Starting Date as Date Filter and Adjustment Exchange Rate Differences Boolean as TRUE on Handler - CustomerTotalBalanceRequestPageHandler.
        EnqueueTotalBalanceReports(AccountingPeriod."Starting Date", true);

        // Exercise: Run Report - Customer Total-Balance set Date Filter and Adjustment Exchange Rate Differences as TRUE on Handler - CustomerTotalBalanceRequestPageHandler.
        asserterror REPORT.Run(REPORT::"Customer Total-Balance");

        // Verify: Verify Error Code for Error message - Accounting Period is not available.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('CustomerTotalBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportAdjustExchRateDifferencesCustTotalBal()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 11003 - Customer Total-Balance.
        // Setup.
        Initialize();
        CreateCustomer();
        EnqueueTotalBalanceReports(WorkDate(), false);  // Enqueue Work Date and Adjustment Exchange Rate Differences Boolean as FALSE on Handler - CustomerTotalBalanceRequestPageHandler.

        // Exercise: Run Report - Customer Total-Balance set Date Filter and Adjustment Exchange Rate Differences as FALSE on Handler - CustomerTotalBalanceRequestPageHandler.
        REPORT.Run(REPORT::"Customer Total-Balance");

        // Verify: Verify Adjustment Text on Report - Customer Total-Balance.
        VerifyTotalBalanceReports(AdjustmentCap, StrSubstNo(AdjustmentValueTxt, ';'));  // Using terminator symbol to replace it in AdjustmentValueTxt.
    end;

    [Test]
    [HandlerFunctions('CustomerTotalBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerLedgerEntryNoCustTotBal()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DebitAmountLCY: Decimal;
        CreditAmountLCY: Decimal;
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Customer on Report 11003 - Customer Total-Balance.

        // Setup: Create two Detailed Customer Ledger Entry with same Customer Ledger Entry No.
        Initialize();
        DebitAmountLCY := LibraryRandom.RandDecInRange(1, 10, 2);  // Generating Debit Amount LCY greater than zero.
        CreditAmountLCY := DebitAmountLCY + LibraryRandom.RandDecInRange(1, 10, 2);  // Credit Amount LCY greater than Debit Amount LCY.
        CustLedgerEntry.FindLast();
        CreateDetailedCustLedgEntry(DetailedCustLedgEntry, CreateCustomer(), DebitAmountLCY, DebitAmountLCY, 0, DetailedCustLedgEntry."Entry Type"::"Realized Loss", DetailedCustLedgEntry."Document Type", CustLedgerEntry."Entry No.");  // Credit Amount LCY 0.

        // Debit Amount LCY - 0.
        CreateDetailedCustLedgEntry(
          DetailedCustLedgEntry2, DetailedCustLedgEntry."Customer No.", -CreditAmountLCY, 0, CreditAmountLCY, DetailedCustLedgEntry2."Entry Type"::"Initial Entry", DetailedCustLedgEntry."Document Type"::Payment, CustLedgerEntry."Entry No.");
        EnqueueTotalBalanceReports(WorkDate(), true);  // Enqueue Date Filter and Adjustment Exchange Rate Differences Boolean as TRUE on Handler - CustomerTotalBalanceRequestPageHandler.

        // Exercise: Run Report - Customer Total-Balance set Date Filter and Adjustment Exchange Rate Differences as TRUE on Handler - CustomerTotalBalanceRequestPageHandler.
        REPORT.Run(REPORT::"Customer Total-Balance");

        // Verify: Verify Period Credit Amount LCY on Report - Customer Total-Balance.
        VerifyTotalBalanceReports(PeriodCreditAmountCap, CreditAmountLCY - DebitAmountLCY);
    end;

    [Test]
    [HandlerFunctions('CustomerTotalBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerClosedByEntryNoCustTotBal()
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Customer on Report 11003 - Customer Total-Balance.

        // Setup: Create Customer Ledger Entry with Entry No equal to Closed by Entry No of created Customer Ledger Entry.
        Initialize();
        OnAfterGetRecordCustomerTotalBalance(true);  // ClosedByEntryNo as TRUE for Customer Ledger Entry.
    end;

    [Test]
    [HandlerFunctions('CustomerTotalBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerEntryNoCustTotBal()
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Customer on Report 11003 - Customer Total-Balance.

        // Setup: Create Customer Ledger Entry with Closed by Entry No equal to Customer Ledger Entry No of created Customer Ledger Entry.
        Initialize();
        OnAfterGetRecordCustomerTotalBalance(false);  // ClosedByEntryNo as FALSE for Customer Ledger Entry.
    end;

    local procedure OnAfterGetRecordCustomerTotalBalance(ClosedByEntryNo: Boolean)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CreditAmountLCY: Decimal;
    begin
        // Create Detailed Customer Ledger Entry with Entry Type Realized Loss. Create Detailed Customer Ledger Entry with Entry Type Initial Entry.

        CreateCustLedgEntryClosedByEntryNo(DetailedCustLedgEntry, CustLedgerEntry, ClosedByEntryNo);
        CreditAmountLCY := DetailedCustLedgEntry."Debit Amount (LCY)" + LibraryRandom.RandDecInRange(1, 10, 2);  // Generating Credit Amount LCY greater than Debit Amount LCY.
        CreateDetailedCustLedgEntry(
          DetailedCustLedgEntry2, DetailedCustLedgEntry."Customer No.", -CreditAmountLCY, 0, CreditAmountLCY, DetailedCustLedgEntry."Entry Type"::"Initial Entry", DetailedCustLedgEntry2."Document Type"::Payment, CustLedgerEntry."Entry No.");
        EnqueueTotalBalanceReports(WorkDate(), true);  // Enqueue Date Filter and Adjustment Exchange Rate Differences Boolean as TRUE on Handler - CustomerTotalBalanceRequestPageHandler.

        // Exercise: Run Report - Customer Total-Balance set Date Filter and Adjustment Exchange Rate Differences as TRUE on Handler - CustomerTotalBalanceRequestPageHandler.
        REPORT.Run(REPORT::"Customer Total-Balance");

        // Verify: Verify Period Credit Amount LCY on Report - Customer Total-Balance.
        VerifyTotalBalanceReports(PeriodCreditAmountCap, CreditAmountLCY - DetailedCustLedgEntry."Debit Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('VendorTotalBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportVendorTotalBalanceError()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 11004 - Vendor Total-Balance.
        // Setup.
        Initialize();
        CreateVendor();
        AccountingPeriod.FindLast();

        // Enqueue Accounting Period  Starting Date as Date Filter and Adjustment Exchange Rate Differences Boolean as TRUE on Handler - VendorTotalBalanceRequestPageHandler.
        EnqueueTotalBalanceReports(AccountingPeriod."Starting Date", true);

        // Exercise: Run Report - Vendor Total-Balance set Date Filter and Adjustment Exchange Rate Differences as TRUE on Handler - VendorTotalBalanceRequestPageHandler.
        asserterror REPORT.Run(REPORT::"Vendor Total-Balance");

        // Verify: Verify Error Code for Error message - Accounting Period is not available.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('VendorTotalBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportAdjustExchRateDifferencesVendTotalBal()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 11004 - Vendor Total-Balance.
        // Setup.
        Initialize();
        CreateVendor();
        EnqueueTotalBalanceReports(WorkDate(), false);  // Enqueue Work Date and Adjustment Exchange Rate Differences Boolean as FALSE on Handler - VendorTotalBalanceRequestPageHandler.

        // Exercise: Run Report - Vendor Total-Balance set Date Filter and Adjustment Exchange Rate Differences as FALSE on Handler - VendorTotalBalanceRequestPageHandler.
        REPORT.Run(REPORT::"Vendor Total-Balance");

        // Verify: Verify Adjustment Text on Report - Vendor Total-Balance.
        VerifyTotalBalanceReports(AdjustmentCap, StrSubstNo(AdjustmentValueTxt, ';'));  // Using terminator symbol to replace it in AdjustmentValueTxt.
    end;

    [Test]
    [HandlerFunctions('VendorTotalBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorLedgerEntryNoVendorTotalBal()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DebitAmountLCY: Decimal;
        CreditAmountLCY: Decimal;
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Vendor on Report 11004 - Vendor Total-Balance.

        // Setup: Create two Detailed Vendor Ledger Entry with same Vendor Ledger Entry No.
        Initialize();
        DebitAmountLCY := LibraryRandom.RandDecInRange(1, 10, 2);  // Generating positive Debit Amount LCY.
        CreditAmountLCY := DebitAmountLCY + LibraryRandom.RandDecInRange(1, 10, 2);  // Credit Amount LCY greater than Debit Amount LCY.
        VendorLedgerEntry.FindLast();
        CreateDetailedVendorLedgEntry(
          DetailedVendorLedgEntry, CreateVendor(), DebitAmountLCY, DebitAmountLCY, 0, DetailedVendorLedgEntry."Entry Type"::"Realized Loss", DetailedVendorLedgEntry."Document Type", VendorLedgerEntry."Entry No.");  // Value 0 for Credit Amount LCY.

        // Value 0 for Debit Amount LCY.
        CreateDetailedVendorLedgEntry(
          DetailedVendorLedgEntry2, DetailedVendorLedgEntry."Vendor No.", -CreditAmountLCY, 0, CreditAmountLCY, DetailedVendorLedgEntry2."Entry Type"::"Initial Entry", DetailedVendorLedgEntry2."Document Type"::Payment, VendorLedgerEntry."Entry No.");
        EnqueueTotalBalanceReports(WorkDate(), true);  // Enqueue Date Filter and Adjustment Exchange Rate Differences Boolean as TRUE on Handler - VendorTotalBalanceRequestPageHandler.

        // Exercise: Run Report - Vendor Total-Balance set Date Filter and Adjustment Exchange Rate Differences as TRUE on Handler - VendorTotalBalanceRequestPageHandler.
        REPORT.Run(REPORT::"Vendor Total-Balance");

        // Verify: Verify Period Credit Amount LCY on Report - Vendor Total-Balance.
        VerifyTotalBalanceReports(PeriodCreditAmountCap, CreditAmountLCY - DebitAmountLCY);
    end;

    [Test]
    [HandlerFunctions('VendorTotalBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorClosedByEntryNoVendTotBal()
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Vendor on Report 11004 - Vendor Total-Balance.

        // Setup: Create Vendor Ledger Entry with Entry No equal to Closed by Entry No of created Vendor Ledger Entry.
        Initialize();
        OnAfterGetRecordVendorTotalBalance(true);  // ClosedByEntryNo as TRUE for Vendor Ledger Entry.
    end;

    [Test]
    [HandlerFunctions('VendorTotalBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorEntryNoVendorTotalBalance()
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Vendor on Report 11004 - Vendor Total-Balance.

        // Setup: Create Vendor Ledger Entry with Closed by Entry No equal to Vendor Ledger Entry No of created Vendor Ledger Entry.
        Initialize();
        OnAfterGetRecordVendorTotalBalance(false);  // ClosedByEntryNo as FALSE for Vendor Ledger Entry.
    end;

    local procedure OnAfterGetRecordVendorTotalBalance(ClosedbyEntryNo: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        CreditAmountLCY: Decimal;
    begin
        // Create Detailed Vendor Ledger Entry with Entry Type Realized Loss. Create Detailed Vendor Ledger Entry with Entry Type Initial Entry.

        CreateVendLedgEntryClosedByEntryNo(DetailedVendorLedgEntry, VendorLedgerEntry, ClosedbyEntryNo);
        CreditAmountLCY := DetailedVendorLedgEntry."Debit Amount (LCY)" + LibraryRandom.RandDecInRange(1, 10, 2);  // Generating Credit Amount LCY greater than Debit Amount LCY.
        CreateDetailedVendorLedgEntry(
          DetailedVendorLedgEntry2, DetailedVendorLedgEntry."Vendor No.", -CreditAmountLCY, 0, CreditAmountLCY, DetailedVendorLedgEntry2."Entry Type"::"Initial Entry", DetailedVendorLedgEntry2."Document Type"::Payment, VendorLedgerEntry."Entry No.");
        EnqueueTotalBalanceReports(WorkDate(), true);  // Enqueue Date Filter and Adjustment Exchange Rate Differences Boolean as TRUE on Handler - VendorTotalBalanceRequestPageHandler.

        // Exercise: Run Report - Vendor Total-Balance set Date Filter and Adjustment Exchange Rate Differences as TRUE on Handler - VendorTotalBalanceRequestPageHandler.
        REPORT.Run(REPORT::"Vendor Total-Balance");

        // Verify: Verify Period Credit Amount LCY on Report - Vendor Total-Balance.
        VerifyTotalBalanceReports(PeriodCreditAmountCap, CreditAmountLCY - DetailedVendorLedgEntry."Debit Amount (LCY)");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        LibraryVariableStorage.Enqueue(Customer."No.");  // Enqueue value for CustomerTotalBalanceRequestPageHandler.
        exit(Customer."No.");
    end;

    local procedure CreateCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; EntryNo: Integer; ClosedByEntryNo: Integer)
    begin
        CustLedgerEntry."Entry No." := EntryNo;
        CustLedgerEntry."Closed by Entry No." := ClosedByEntryNo;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Payment;
        CustLedgerEntry.Insert();
    end;

    local procedure CreateCustLedgEntryClosedByEntryNo(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry"; ClosedByEntryNo: Boolean)
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        // Value 0 for Closed By Entry No.
        CustLedgerEntry2.FindLast();
        if ClosedByEntryNo then begin
            CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry2."Closed by Entry No." + 1, 0);  // New Entry required.
            CreateLedgerEntriesForCustomerWithRealizedLoss(DetailedCustLedgEntry, CustLedgerEntry2."Entry No." + 1, CustLedgerEntry2."Closed by Entry No." + 1);
        end else begin
            CreateLedgerEntriesForCustomerWithRealizedLoss(DetailedCustLedgEntry, CustLedgerEntry."Entry No." + 1, 0);

            // Create Customer Ledger Entry with Closed by Entry No equal to Customer Ledger Entry No of created Detailed Customer Ledger Entry.
            CreateCustomerLedgerEntry(CustLedgerEntry, DetailedCustLedgEntry."Cust. Ledger Entry No." + 1, DetailedCustLedgEntry."Cust. Ledger Entry No.");
        end;
    end;

    local procedure CreateDetailedCustLedgEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustomerNo: Code[20]; AmountLCY: Decimal; DebitAmountLCY: Decimal; CreditAmountLCY: Decimal; EntryType: Enum "Detailed CV Ledger Entry Type"; DocumentType: Enum "Gen. Journal Document Type"; CustLedgerEntryNo: Integer)
    var
        DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry2.FindLast();
        DetailedCustLedgEntry."Entry No." := DetailedCustLedgEntry2."Entry No." + 1;
        DetailedCustLedgEntry."Customer No." := CustomerNo;
        DetailedCustLedgEntry."Posting Date" := WorkDate();
        DetailedCustLedgEntry."Amount (LCY)" := AmountLCY;
        DetailedCustLedgEntry."Debit Amount (LCY)" := DebitAmountLCY;
        DetailedCustLedgEntry."Credit Amount (LCY)" := CreditAmountLCY;
        DetailedCustLedgEntry."Entry Type" := EntryType;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntryNo;
        DetailedCustLedgEntry."Document Type" := DocumentType;
        DetailedCustLedgEntry.Insert(true);
    end;

    local procedure CreateLedgerEntriesForCustomerWithRealizedLoss(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; EntryNo: Integer; ClosedByEntryNo: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DebitAmountLCY: Decimal;
    begin
        DebitAmountLCY := LibraryRandom.RandDecInRange(1, 10, 2);  // Generating Positive Debit Amount LCY.
        CreateCustomerLedgerEntry(CustLedgerEntry, EntryNo, ClosedByEntryNo);
        CreateDetailedCustLedgEntry(
          DetailedCustLedgEntry, CreateCustomer(), DebitAmountLCY, DebitAmountLCY, 0, DetailedCustLedgEntry."Entry Type"::"Realized Loss", DetailedCustLedgEntry."Document Type", CustLedgerEntry."Entry No.");  // Credit Amount LCY 0.
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Enqueue value for VendorTotalBalanceRequestPageHandler.
        exit(Vendor."No.");
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; EntryNo: Integer; ClosedByEntryNo: Integer)
    begin
        VendorLedgerEntry."Entry No." := EntryNo;
        VendorLedgerEntry."Closed by Entry No." := ClosedByEntryNo;
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Payment;
        VendorLedgerEntry.Insert();
    end;

    local procedure CreateVendLedgEntryClosedByEntryNo(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; ClosedbyEntryNo: Boolean)
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        // Value 0 for Closed By Entry No.
        VendorLedgerEntry2.FindLast();
        if ClosedbyEntryNo then begin
            CreateVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Closed by Entry No." + 1, 0);  // New Entry required.
            CreateLedgerEntriesForVendorWithRealizedLoss(DetailedVendorLedgEntry, VendorLedgerEntry."Entry No." + 1, VendorLedgerEntry."Closed by Entry No." + 1);
        end else begin
            CreateLedgerEntriesForVendorWithRealizedLoss(DetailedVendorLedgEntry, VendorLedgerEntry."Entry No." + 1, 0);

            // Create Vendor Ledger Entry with Closed by Entry No equal to Vendor Ledger Entry No of created Detailed Vendor Ledger Entry.
            CreateVendorLedgerEntry(VendorLedgerEntry, DetailedVendorLedgEntry."Vendor Ledger Entry No." + 1, DetailedVendorLedgEntry."Vendor Ledger Entry No.");  // Using Detailed Vendor Ledger Entry for Entry No.
        end;
    end;

    local procedure CreateDetailedVendorLedgEntry(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; VendorNo: Code[20]; AmountLCY: Decimal; DebitAmountLCY: Decimal; CreditAmountLCY: Decimal; EntryType: Enum "Detailed CV Ledger Entry Type"; DocumentType: Enum "Gen. Journal Document Type"; VendorLedgerEntryNo: Integer)
    var
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry2.FindLast();
        DetailedVendorLedgEntry."Entry No." := DetailedVendorLedgEntry2."Entry No." + 1;
        DetailedVendorLedgEntry."Vendor No." := VendorNo;
        DetailedVendorLedgEntry."Posting Date" := WorkDate();
        DetailedVendorLedgEntry."Amount (LCY)" := AmountLCY;
        DetailedVendorLedgEntry."Debit Amount (LCY)" := DebitAmountLCY;
        DetailedVendorLedgEntry."Credit Amount (LCY)" := CreditAmountLCY;
        DetailedVendorLedgEntry."Entry Type" := EntryType;
        DetailedVendorLedgEntry."Document Type" := DocumentType;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntryNo;
        DetailedVendorLedgEntry.Insert(true);
    end;

    local procedure CreateLedgerEntriesForVendorWithRealizedLoss(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; EntryNo: Integer; ClosedByEntryNo: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DebitAmountLCY: Decimal;
    begin
        DebitAmountLCY := LibraryRandom.RandDecInRange(1, 10, 2);  // Generating Positive Debit Amount.
        CreateVendorLedgerEntry(VendorLedgerEntry, EntryNo, ClosedByEntryNo);

        // Credit Amount LCY - 0.
        CreateDetailedVendorLedgEntry(DetailedVendorLedgEntry, CreateVendor(), DebitAmountLCY, DebitAmountLCY, 0, DetailedVendorLedgEntry."Entry Type"::"Realized Loss", DetailedVendorLedgEntry."Document Type", VendorLedgerEntry."Entry No.");
    end;

    local procedure EnqueueTotalBalanceReports(DateFilter: Date; AdjustExchRateDifferences: Boolean)
    begin
        LibraryVariableStorage.Enqueue(DateFilter);
        LibraryVariableStorage.Enqueue(AdjustExchRateDifferences);
    end;

    local procedure VerifyTotalBalanceReports(ElementName: Text; ExpectedValue: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ElementName, ExpectedValue);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTotalBalanceRequestPageHandler(var CustomerTotalBalance: TestRequestPage "Customer Total-Balance")
    var
        DateFilter: Variant;
        No: Variant;
        AdjustExchRateDifferences: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(AdjustExchRateDifferences);
        CustomerTotalBalance.Customer.SetFilter("No.", No);
        CustomerTotalBalance.Customer.SetFilter("Date Filter", Format(DateFilter));
        CustomerTotalBalance.AdjustExchRateDifferences.SetValue(AdjustExchRateDifferences);
        CustomerTotalBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorTotalBalanceRequestPageHandler(var VendorTotalBalance: TestRequestPage "Vendor Total-Balance")
    var
        DateFilter: Variant;
        No: Variant;
        AdjustExchRateDifferences: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(AdjustExchRateDifferences);
        VendorTotalBalance.Vendor.SetFilter("No.", No);
        VendorTotalBalance.Vendor.SetFilter("Date Filter", Format(DateFilter));
        VendorTotalBalance.AdjustExchRateDifferences.SetValue(AdjustExchRateDifferences);
        VendorTotalBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

