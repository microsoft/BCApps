codeunit 144057 "UT COD Telebank"
{
    // // [FEATURE] [Telebank] [UT]
    //  1. Test to verify that Transaction Mode Code and Bank Account Code are same on Customer Ledger Entry after running Cust. Entry-Edit.
    //  2. Test to verify that Transaction Mode Code and Bank Account Code are same on Vendor Ledger Entry after running Vend. Entry-Edit.
    // 
    //  Covers Test Cases for WI - 343638
    //  ------------------------------------------------------
    //  Test Function Name                             TFS ID
    //  ------------------------------------------------------
    //  OnRunCustomerEntryEdit
    //  OnRunVendorEntryEdit

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunCustomerEntryEdit()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        // Purpose of the test is to validate the OnRun trigger of the Codeunit ID::103, Cust. Entry-Edit.

        // Setup: Create Customer, create Customer Ledger Entry.
        CreateCustomer(Customer);
        CreateCustomerLedgerEntry(CustLedgerEntry, Customer."No.", Customer."Transaction Mode Code");

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgerEntry);

        // Verify: Verify that Transaction Mode Code and Bank Account Code are same on Customer Ledger Entry after running Cust. Entry-Edit.
        CustLedgerEntry2.SetRange("Document No.", CustLedgerEntry."Document No.");
        CustLedgerEntry2.FindFirst();
        CustLedgerEntry2.TestField("Transaction Mode Code", CustLedgerEntry."Transaction Mode Code");
        CustLedgerEntry2.TestField("Recipient Bank Account", CustLedgerEntry."Recipient Bank Account");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunVendorEntryEdit()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate the OnRun trigger of the Codeunit ID::113, Vend. Entry-Edit.

        // Setup: Create Vendor, create Vendor Ledger Entry.
        CreateVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", Vendor."Transaction Mode Code");

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendorLedgerEntry);

        // Verify: Verify the Transaction Mode Code and Bank Account Code are same on Vendor Ledger Entry after running Vend. Entry-Edit.
        VendorLedgerEntry2.SetRange("Document No.", VendorLedgerEntry."Document No.");
        VendorLedgerEntry2.FindFirst();
        VendorLedgerEntry2.TestField("Transaction Mode Code", VendorLedgerEntry."Transaction Mode Code");
        VendorLedgerEntry2.TestField("Recipient Bank Account", VendorLedgerEntry."Recipient Bank Account");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunEmployeeEntryEdit()
    var
        Employee: Record Employee;
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        EmployeeLedgerEntry2: Record "Employee Ledger Entry";
    begin
        // Purpose of the test is to validate the OnRun trigger of the Codeunit ID::113, Vend. Entry-Edit.

        // Setup: Create Vendor, create Vendor Ledger Entry.
        CreateEmployee(Employee);
        CreateEmployeeLedgerEntry(EmployeeLedgerEntry, Employee."No.", Employee."Transaction Mode Code");

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", EmployeeLedgerEntry);

        // Verify: Verify the Transaction Mode Code and Bank Account Code are same on Vendor Ledger Entry after running Vend. Entry-Edit.
        EmployeeLedgerEntry2.SetRange("Document No.", EmployeeLedgerEntry."Document No.");
        EmployeeLedgerEntry2.FindFirst();
        EmployeeLedgerEntry2.TestField("Transaction Mode Code", EmployeeLedgerEntry."Transaction Mode Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnRunSEPACTPrepareSource()
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        PaymentHistoryLine: Record "Payment History Line";
        AppliesToDocNo: Code[20];
    begin
        CreatePaymentHistoryLines(PaymentHistoryLine, AppliesToDocNo);

        // Exercise.
        TempGenJnlLine.SetRange("Bal. Account No.", PaymentHistoryLine."Our Bank");
        TempGenJnlLine.SetRange("Document No.", PaymentHistoryLine."Run No.");
        CODEUNIT.Run(CODEUNIT::"SEPA CT-Prepare Source", TempGenJnlLine);

        // Verify.
        VerifyTempJnlLineVsPmtHistoryLine(TempGenJnlLine, PaymentHistoryLine, AppliesToDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetailLinesAreUpdatedWithStatusPostedAfterSetApplyCVLedgerEntriesWithPost()
    var
        PaymentHistoryLine: Record "Payment History Line";
        DetailLine: Record "Detail Line";
        FinancialInterfaceTelebank: Codeunit "Financial Interface Telebank";
    begin
        // [SCENARIO 209402] COD 11000001 "Financial Interface Telebank".SetApplyCVLedgerEntries() updates "Detail Line".Status from "In process" to "Posted"
        // [SCENARIO 209402] in case of Post = TRUE and several detail lines

        // [GIVEN] Payment History Line with several related Detail Lines with Status = "In process"
        CreatePaymentHistoryLineWithTwoDetailLines(PaymentHistoryLine, DetailLine);

        // [WHEN] Perform COD 11000001 "Financial Interface Telebank".SetApplyCVLedgerEntries() with Post = TRUE
        DetailLine.SetRange(Status, DetailLine.Status::"In process");
        Assert.RecordCount(DetailLine, 2);
        FinancialInterfaceTelebank.SetApplyCVLedgerEntries(PaymentHistoryLine, '', true, false);

        // [THEN] Detail Lines are updated with Status = "Posted"
        Assert.RecordIsEmpty(DetailLine);
        DetailLine.SetRange(Status, DetailLine.Status::Posted);
        Assert.RecordCount(DetailLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetailLinesAreNotUpdatedWithStatusPostedAfterSetApplyCVLedgerEntriesWithoutPost()
    var
        PaymentHistoryLine: Record "Payment History Line";
        DetailLine: Record "Detail Line";
        FinancialInterfaceTelebank: Codeunit "Financial Interface Telebank";
    begin
        // [SCENARIO 209402] COD 11000001 "Financial Interface Telebank".SetApplyCVLedgerEntries() doesn't update "Detail Line".Status from "In process" to "Posted"
        // [SCENARIO 209402] in case of Post = FALSE and several detail lines

        // [GIVEN] Payment History Line with several related Detail Lines with Status = "In process"
        CreatePaymentHistoryLineWithTwoDetailLines(PaymentHistoryLine, DetailLine);

        // [WHEN] Perform COD 11000001 "Financial Interface Telebank".SetApplyCVLedgerEntries() with Post = FALSE
        DetailLine.SetRange(Status, DetailLine.Status::"In process");
        Assert.RecordCount(DetailLine, 2);
        FinancialInterfaceTelebank.SetApplyCVLedgerEntries(PaymentHistoryLine, '', false, false);

        // [THEN] Detail Lines are updated with Status = "Posted"
        Assert.RecordCount(DetailLine, 2);
        DetailLine.SetRange(Status, DetailLine.Status::Posted);
        Assert.RecordIsEmpty(DetailLine);
    end;

    local procedure CreatePaymentHistoryLineWithTwoDetailLines(var PaymentHistoryLine: Record "Payment History Line"; var DetailLine: Record "Detail Line")
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: array[2] of Record "Vendor Ledger Entry";
        PaymentHistory: Record "Payment History";
    begin
        CreateVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry[1], Vendor."No.", Vendor."Transaction Mode Code");
        CreateVendorLedgerEntry(VendorLedgerEntry[2], Vendor."No.", Vendor."Transaction Mode Code");

        MockPaymentHistory(PaymentHistory);
        MockPaymentHistoryLine(PaymentHistoryLine, PaymentHistory);
        MockDetailLine(DetailLine, PaymentHistoryLine, VendorLedgerEntry[1]."Entry No.");
        MockDetailLine(DetailLine, PaymentHistoryLine, VendorLedgerEntry[2]."Entry No.");

        DetailLine.SetRange("Our Bank", PaymentHistoryLine."Our Bank");
        DetailLine.SetRange("Connect Batches", PaymentHistoryLine."Run No.");
        DetailLine.SetRange("Connect Lines", PaymentHistoryLine."Line No.");
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    var
        DummyTransactionMode: Record "Transaction Mode";
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer."Transaction Mode Code" := CreateTransactionMode(DummyTransactionMode."Account Type"::Customer);
        Customer.Insert();
    end;

    local procedure CreateCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; TransactionModeCode: Code[20])
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        if CustLedgerEntry2.FindLast() then
            CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1
        else
            CustLedgerEntry."Entry No." := 1;
        CustLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Transaction Mode Code" := TransactionModeCode;
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CustLedgerEntry."Customer No.");
        CustLedgerEntry."Recipient Bank Account" := CustomerBankAccount.Code;
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();
    end;

    local procedure CreatePaymentHistoryLines(var PaymentHistoryLine: Record "Payment History Line"; var AppliesToDocNo: Code[20])
    var
        PaymentHistory: Record "Payment History";
        DetailLine: Record "Detail Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        MockPaymentHistory(PaymentHistory);

        MockPaymentHistoryLine(PaymentHistoryLine, PaymentHistory);
        // second line
        PaymentHistoryLine."Line No." += 1;
        PaymentHistoryLine."Account Type" := PaymentHistoryLine."Account Type"::Vendor;
        PaymentHistoryLine.Insert();

        VendLedgEntry.SetFilter("External Document No.", '<>%1', '');
        VendLedgEntry.FindFirst();
        AppliesToDocNo := VendLedgEntry."External Document No.";
        MockDetailLine(DetailLine, PaymentHistoryLine, VendLedgEntry."Entry No.");

        PaymentHistoryLine.SetRange("Our Bank", PaymentHistory."Our Bank");
        PaymentHistoryLine.SetRange("Run No.", PaymentHistory."Run No.");
    end;

    local procedure CreateTransactionMode(AccountType: Option): Code[20]
    var
        TransactionMode: Record "Transaction Mode";
    begin
        TransactionMode.Code := LibraryUTUtility.GetNewCode();
        TransactionMode."Account Type" := AccountType;
        TransactionMode.Insert();
        exit(TransactionMode.Code);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    var
        DummyTransactionMode: Record "Transaction Mode";
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor."Transaction Mode Code" := CreateTransactionMode(DummyTransactionMode."Account Type"::Vendor);
        Vendor.Insert();
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; TransactionModeCode: Code[20])
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        if VendorLedgerEntry2.FindLast() then
            VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1
        else
            VendorLedgerEntry."Entry No." := 1;
        VendorLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Transaction Mode Code" := TransactionModeCode;
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorLedgerEntry."Vendor No.");
        VendorLedgerEntry."Recipient Bank Account" := VendorBankAccount.Code;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();
    end;

    local procedure CreateEmployee(var Employee: Record Employee)
    var
        DummyTransactionMode: Record "Transaction Mode";
    begin
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);
        Employee."Transaction Mode Code" := CreateTransactionMode(DummyTransactionMode."Account Type"::Employee);
        Employee.Modify(true);
    end;

    local procedure CreateEmployeeLedgerEntry(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; EmployeeNo: Code[20]; TransactionModeCode: Code[20])
    var
        EmployeeLedgerEntry2: Record "Employee Ledger Entry";
    begin
        if EmployeeLedgerEntry2.FindLast() then
            EmployeeLedgerEntry."Entry No." := EmployeeLedgerEntry2."Entry No." + 1
        else
            EmployeeLedgerEntry."Entry No." := 1;
        EmployeeLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        EmployeeLedgerEntry."Employee No." := EmployeeNo;
        EmployeeLedgerEntry."Transaction Mode Code" := TransactionModeCode;
        EmployeeLedgerEntry.Open := true;
        EmployeeLedgerEntry.Insert();
    end;

    local procedure MockPaymentHistory(var PaymentHistory: Record "Payment History")
    begin
        PaymentHistory.Init();
        PaymentHistory."Our Bank" := LibraryUTUtility.GetNewCode();
        PaymentHistory."Run No." := LibraryUTUtility.GetNewCode();
        PaymentHistory.Insert();
    end;

    local procedure MockPaymentHistoryLine(var PaymentHistoryLine: Record "Payment History Line"; PaymentHistory: Record "Payment History")
    begin
        PaymentHistoryLine.Init();
        PaymentHistoryLine."Our Bank" := PaymentHistory."Our Bank";
        PaymentHistoryLine."Run No." := PaymentHistory."Run No.";
        PaymentHistoryLine."Line No." := 1;
        PaymentHistoryLine."Account Type" := PaymentHistoryLine."Account Type"::Customer;
        PaymentHistoryLine."Account No." := LibraryUTUtility.GetNewCode();
        PaymentHistoryLine.Date := WorkDate();
        PaymentHistoryLine.Amount := 1;
        PaymentHistoryLine.Bank := LibraryUTUtility.GetNewCode10();
        PaymentHistoryLine."Currency Code" := LibraryUTUtility.GetNewCode10();
        PaymentHistoryLine."Description 1" := LibraryUTUtility.GetNewCode();
        PaymentHistoryLine.Insert();
    end;

    local procedure MockDetailLine(var DetailLine: Record "Detail Line"; PaymentHistoryLine: Record "Payment History Line"; SerialNoEntry: Integer)
    begin
        DetailLine.Init();
        DetailLine."Transaction No." := LibraryUtility.GetNewRecNo(DetailLine, DetailLine.FieldNo("Transaction No."));
        DetailLine."Our Bank" := PaymentHistoryLine."Our Bank";
        DetailLine.Status := DetailLine.Status::"In process";
        DetailLine."Connect Batches" := PaymentHistoryLine."Run No.";
        DetailLine."Connect Lines" := PaymentHistoryLine."Line No.";
        DetailLine."Account Type" := DetailLine."Account Type"::Vendor;
        DetailLine."Serial No. (Entry)" := SerialNoEntry;
        DetailLine.Insert();
    end;

    local procedure VerifyTempJnlLineVsPmtHistoryLine(var TempGenJnlLine: Record "Gen. Journal Line" temporary; var PaymentHistoryLine: Record "Payment History Line"; AppliesToDocNo: Code[20])
    var
        DocumentType: Enum "Gen. Journal Document Type";
    begin
        Assert.AreEqual(PaymentHistoryLine.Count, TempGenJnlLine.Count, 'Wrong count');
        PaymentHistoryLine.FindSet();
        TempGenJnlLine.FindSet();
        repeat
            Assert.AreEqual('', TempGenJnlLine."Journal Template Name", TempGenJnlLine.FieldName("Journal Template Name"));
            Assert.AreEqual('', TempGenJnlLine."Journal Batch Name", TempGenJnlLine.FieldName("Journal Batch Name"));
            Assert.AreEqual(TempGenJnlLine."Bal. Account Type"::"Bank Account", TempGenJnlLine."Bal. Account Type", TempGenJnlLine.FieldName("Bal. Account Type"));
            Assert.AreEqual(PaymentHistoryLine."Our Bank", TempGenJnlLine."Bal. Account No.", TempGenJnlLine.FieldName("Bal. Account No."));
            Assert.AreEqual(PaymentHistoryLine."Run No.", TempGenJnlLine."Document No.", TempGenJnlLine.FieldName("Document No."));
            Assert.AreEqual(PaymentHistoryLine."Line No.", TempGenJnlLine."Line No.", TempGenJnlLine.FieldName("Line No."));
            Assert.AreEqual(PaymentHistoryLine."Account Type" + 1, TempGenJnlLine."Account Type", TempGenJnlLine.FieldName("Account Type"));
            if TempGenJnlLine."Account Type" = TempGenJnlLine."Account Type"::Customer then
                DocumentType := TempGenJnlLine."Document Type"::Refund
            else
                DocumentType := TempGenJnlLine."Document Type"::Payment;
            Assert.AreEqual(DocumentType, TempGenJnlLine."Document Type", TempGenJnlLine.FieldName("Document Type"));
            Assert.AreEqual(PaymentHistoryLine."Account No.", TempGenJnlLine."Account No.", TempGenJnlLine.FieldName("Account No."));
            Assert.AreEqual(PaymentHistoryLine.Date, TempGenJnlLine."Posting Date", TempGenJnlLine.FieldName("Posting Date"));
            Assert.AreEqual(PaymentHistoryLine.Amount, TempGenJnlLine.Amount, TempGenJnlLine.FieldName(Amount));
            Assert.AreEqual(PaymentHistoryLine."Currency Code", TempGenJnlLine."Currency Code", TempGenJnlLine.FieldName("Currency Code"));
            Assert.AreEqual(PaymentHistoryLine.Bank, TempGenJnlLine."Recipient Bank Account", TempGenJnlLine.FieldName("Recipient Bank Account"));
            if TempGenJnlLine."Account Type" = TempGenJnlLine."Account Type"::Vendor then
                PaymentHistoryLine."Description 1" := AppliesToDocNo;
            Assert.AreEqual(PaymentHistoryLine."Description 1", TempGenJnlLine.Description, TempGenJnlLine.FieldName(Description));
            PaymentHistoryLine.Next();
        until TempGenJnlLine.Next() = 0;
    end;
}

