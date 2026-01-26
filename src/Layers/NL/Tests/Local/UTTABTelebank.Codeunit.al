codeunit 144055 "UT TAB Telebank"
{
    //  1. Purpose of the test is to validate Bill-to Customer No. of Service Contract Header Table.
    //  2. Purpose of the test is to validate Transaction Mode Code of Service Contract Header Table.
    //  3. Purpose of the test is to validate Transaction Mode Code of Service Invoice Header Table.
    //  4. Purpose of the test is to validate Transaction Mode Code of Service Cr. Memo Header Table.
    //  5. Purpose of the test is to validate Account No of Customer of Gen. Journal Line Table.
    //  6. Purpose of the test is to validate Account No of Vendor of Gen. Journal Line Table.
    //  7. Purpose of the test is to validate Transaction Mode Code of Gen. Journal Line Table for Customer.
    //  8. Purpose of the test is to validate Transaction Mode Code of Gen. Journal Line Table for Vendor.
    //  9. Purpose of the test is to validate Transaction Mode Code of Gen. Journal Line Table for GL Account And Customer.
    // 10. Purpose of the test is to validate Transaction Mode Code of Gen. Journal Line Table for GL Account And Vendor.
    // 11. Purpose of the test is to validate Transaction Mode Code of Gen. Journal Line Table for GL Account And GL Account.
    // 
    // Covers Test Cases for WI - 343629
    // -------------------------------------------------------------------------------------------------
    // Test Function Name
    // -------------------------------------------------------------------------------------------------
    // OnValidateBillToCustomerNoServiceContractHeader,OnValidateTransactionModeServiceContractHeader
    // OnValidateTransactionModeServiceInvoiceHeader,OnValidateTransactionModeServiceCrMemoHeader
    // OnValidateAccountNoGenJournalLineCust,OnValidateAccountNoGenJournalLineVend
    // OnValidateTransactionModeGenJournalLineCust,OnValidateTransactionModeGenJournalLineVend
    // OnValidateTransactionModeGenJournalLineGLAndCust,OnValidateTransactionModeGenJournalLineGLAndVend
    // OnValidateTransactionModeGenJournalLineError

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        AppliedDocNoListErr: Label 'Wrong list of applied document numbers.';
        LibraryRandom: Codeunit "Library - Random";
        MustHaveValueErr: Label '%1 must have a value';
        CannotBeFoundErr: Label 'cannot be found in the related table';
        LibraryHumanResource: Codeunit "Library - Human Resource";
        ExportErrorsPerLine: Integer;
        LinesPerPaymentHistory: Integer;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AppliedDocListCust()
    var
        PaymentHistoryLine: Record "Payment History Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DocumentNo: array[2] of Code[20];
    begin
        PaymentHistoryLine.Init();
        PaymentHistoryLine."Account Type" := PaymentHistoryLine."Account Type"::Customer;
        PaymentHistoryLine."Account No." := LibrarySales.CreateCustomerNo();

        DocumentNo[1] := InsertCustLedgEntry(CustLedgEntry, PaymentHistoryLine);
        DocumentNo[2] := InsertCustLedgEntry(CustLedgEntry, PaymentHistoryLine);

        VerifyAppliedDocNoList(PaymentHistoryLine, DocumentNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AppliedDocListVend()
    var
        PaymentHistoryLine: Record "Payment History Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DocumentNo: array[2] of Code[35];
    begin
        PaymentHistoryLine.Init();
        PaymentHistoryLine."Account Type" := PaymentHistoryLine."Account Type"::Vendor;
        PaymentHistoryLine."Account No." := LibraryPurchase.CreateVendorNo();

        DocumentNo[1] := InsertVendLedgEntry(VendLedgEntry, PaymentHistoryLine);
        DocumentNo[2] := InsertVendLedgEntry(VendLedgEntry, PaymentHistoryLine);

        VerifyAppliedDocNoList(PaymentHistoryLine, DocumentNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AppliedDocListEmpl()
    var
        PaymentHistoryLine: Record "Payment History Line";
        EmplLedgEntry: Record "Employee Ledger Entry";
        DocumentNo: array[2] of Code[20];
    begin
        PaymentHistoryLine.Init();
        PaymentHistoryLine."Account Type" := PaymentHistoryLine."Account Type"::Employee;
        PaymentHistoryLine."Account No." := LibraryHumanResource.CreateEmployeeNoWithBankAccount();

        DocumentNo[1] := InsertEmplLedgEntry(EmplLedgEntry, PaymentHistoryLine);
        DocumentNo[2] := InsertEmplLedgEntry(EmplLedgEntry, PaymentHistoryLine);

        VerifyAppliedDocNoList(PaymentHistoryLine, DocumentNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AppliedDocNoListCust()
    var
        PaymentHistoryLine: Record "Payment History Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        PaymentHistoryLine.Init();
        PaymentHistoryLine."Account Type" := PaymentHistoryLine."Account Type"::Customer;
        PaymentHistoryLine."Account No." := LibrarySales.CreateCustomerNo();

        InsertCustLedgEntry(CustLedgEntry, PaymentHistoryLine);

        Assert.AreEqual(
          CustLedgEntry."Document No.", PaymentHistoryLine.GetAppliedDocNoList(MaxStrLen(CustLedgEntry."Document No.")),
          AppliedDocNoListErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AppliedDocNoListVend()
    var
        PaymentHistoryLine: Record "Payment History Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        PaymentHistoryLine.Init();
        PaymentHistoryLine."Account Type" := PaymentHistoryLine."Account Type"::Vendor;
        PaymentHistoryLine."Account No." := LibraryPurchase.CreateVendorNo();

        InsertVendLedgEntry(VendLedgEntry, PaymentHistoryLine);

        Assert.AreEqual(
          VendLedgEntry."External Document No.", PaymentHistoryLine.GetAppliedDocNoList(MaxStrLen(VendLedgEntry."External Document No.")),
          AppliedDocNoListErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AppliedDocNoListEmpl()
    var
        PaymentHistoryLine: Record "Payment History Line";
        EmplLedgEntry: Record "Employee Ledger Entry";
    begin
        PaymentHistoryLine.Init();
        PaymentHistoryLine."Account Type" := PaymentHistoryLine."Account Type"::Employee;
        PaymentHistoryLine."Account No." := LibraryHumanResource.CreateEmployeeNoWithBankAccount();

        InsertEmplLedgEntry(EmplLedgEntry, PaymentHistoryLine);

        Assert.AreEqual(
          EmplLedgEntry."Document No.", PaymentHistoryLine.GetAppliedDocNoList(MaxStrLen(EmplLedgEntry."Document No.")),
          AppliedDocNoListErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CollectAccHolderDataOnPaymentExportBuffer()
    var
        GenJnlLine: Record "Gen. Journal Line";
        PaymentHistoryLine: Record "Payment History Line";
        PaymentExportBuffer: Record "Payment Export Data";
    begin
        PaymentHistoryLine.Init();
        PaymentHistoryLine."Our Bank" := PaymentHistoryLine.FieldName("Our Bank");
        PaymentHistoryLine."Run No." := PaymentHistoryLine.FieldName("Run No.");
        PaymentHistoryLine."Line No." := 1;
        PaymentHistoryLine."Account Holder Name" := PaymentHistoryLine.FieldName("Account Holder Name");
        PaymentHistoryLine."Account Holder Address" := PaymentHistoryLine.FieldName("Account Holder Address");
        PaymentHistoryLine."Account Holder City" := PaymentHistoryLine.FieldName("Account Holder City");
        PaymentHistoryLine."Account Holder Post Code" := '1234';
        PaymentHistoryLine."Acc. Hold. Country/Region Code" := 'XX';
        PaymentHistoryLine.Urgent := false;
        PaymentHistoryLine.Insert();

        GenJnlLine.Init();
        GenJnlLine."Bal. Account No." := PaymentHistoryLine."Our Bank";
        GenJnlLine."Document No." := PaymentHistoryLine."Run No.";
        GenJnlLine."Line No." := PaymentHistoryLine."Line No.";

        PaymentExportBuffer.Init();
        // Exercise.
        PaymentExportBuffer.CollectDataFromLocalSource(GenJnlLine);
        // Verify.
        Assert.AreEqual(PaymentHistoryLine."Account Holder Name", PaymentExportBuffer."Recipient Name", PaymentExportBuffer.FieldName("Recipient Name"));
        Assert.AreEqual(PaymentHistoryLine."Account Holder Address", PaymentExportBuffer."Recipient Address", PaymentExportBuffer.FieldName("Recipient Address"));
        Assert.AreEqual(PaymentHistoryLine."Account Holder City", PaymentExportBuffer."Recipient City", PaymentExportBuffer.FieldName("Recipient City"));
        Assert.AreEqual(PaymentHistoryLine."Account Holder Post Code", PaymentExportBuffer."Recipient Post Code", PaymentExportBuffer.FieldName("Recipient Post Code"));
        Assert.AreEqual(
          PaymentHistoryLine."Acc. Hold. Country/Region Code", PaymentExportBuffer."Recipient Country/Region Code",
          PaymentExportBuffer.FieldName("Recipient Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CollectUrgentFieldOnPaymentExportBuffer()
    var
        GenJnlLine: Record "Gen. Journal Line";
        PaymentHistoryLine: Record "Payment History Line";
        PaymentExportBuffer: Record "Payment Export Data";
    begin
        PaymentHistoryLine.Init();
        PaymentHistoryLine."Our Bank" := PaymentHistoryLine.FieldName("Our Bank");
        PaymentHistoryLine."Run No." := PaymentHistoryLine.FieldName("Run No.");
        PaymentHistoryLine."Line No." := 1;

        GenJnlLine.Init();
        GenJnlLine."Bal. Account No." := PaymentHistoryLine."Our Bank";
        GenJnlLine."Document No." := PaymentHistoryLine."Run No.";
        GenJnlLine."Line No." := PaymentHistoryLine."Line No.";

        PaymentHistoryLine.Urgent := false;
        PaymentHistoryLine.Insert();

        PaymentExportBuffer.Init();
        PaymentExportBuffer.CollectDataFromLocalSource(GenJnlLine);
        Assert.AreEqual('NORM', PaymentExportBuffer."SEPA Instruction Priority Text", PaymentExportBuffer.FieldName("SEPA Instruction Priority Text"));

        PaymentHistoryLine.Urgent := true;
        PaymentHistoryLine.Modify();

        PaymentExportBuffer.Init();
        PaymentExportBuffer.CollectDataFromLocalSource(GenJnlLine);
        Assert.AreEqual('HIGH', PaymentExportBuffer."SEPA Instruction Priority Text", PaymentExportBuffer.FieldName("SEPA Instruction Priority Text"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure MandatoryDefaultFileNames()
    var
        ExportProtocol: Record "Export Protocol";
        PaymentHistory: Record "Payment History";
    begin
        MockExportProtocol(ExportProtocol, '');

        PaymentHistory.Init();
        PaymentHistory."Export Protocol" := ExportProtocol.Code;
        asserterror PaymentHistory.GenerateExportfilename(false);
        Assert.ExpectedError(StrSubstNo(MustHaveValueErr, ExportProtocol.FieldCaption("Default File Names")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnDeletePaymentHistoryLineWithExportErrors()
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        PaymentHistory: Record "Payment History";
        PaymentHistoryLine: Record "Payment History Line";
    begin
        Initialize();
        PaymentJnlExportErrorText.Reset();
        PaymentJnlExportErrorText.DeleteAll();

        CreatePaymentHistory(PaymentHistory);
        CreatePaymentHistoryLinesWithExportErrors(PaymentHistory, PaymentHistoryLine);

        CreatePaymentHistories(PaymentHistory);

        // Exercise
        PaymentHistoryLine.Delete(true);

        // Verify
        Assert.AreEqual(
          3 * LinesPerPaymentHistory * ExportErrorsPerLine - ExportErrorsPerLine, PaymentJnlExportErrorText.Count, 'Total Count');
        VerifyNoExportErrors(PaymentHistoryLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnDeletePaymentHistoryWithExportErrors()
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        PaymentHistory: Record "Payment History";
        PaymentHistoryLine: Record "Payment History Line";
    begin
        Initialize();
        PaymentJnlExportErrorText.Reset();
        PaymentJnlExportErrorText.DeleteAll();

        CreatePaymentHistory(PaymentHistory);
        CreatePaymentHistoryLinesWithExportErrors(PaymentHistory, PaymentHistoryLine);

        CreatePaymentHistories(PaymentHistory);

        // Exercise
        PaymentHistory.Delete(true);

        // Verify
        Assert.AreEqual(2 * LinesPerPaymentHistory * ExportErrorsPerLine, PaymentJnlExportErrorText.Count, 'Total Count');
        PaymentHistoryLine."Line No." := 0;
        VerifyNoExportErrors(PaymentHistoryLine);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToCustomerNoServiceContractHeader()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // Purpose of the test is to validate Bill-to Customer No. of Service Contract Header Table.

        // Setup.
        Initialize();
        CreateCustomer(Customer);
        CreateServiceContractHeader(ServiceContractHeader);

        // Exercise.
        ServiceContractHeader.Validate("Bill-to Customer No.", Customer."No.");
        ServiceContractHeader.Modify();

        // Verify.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.TestField("Transaction Mode Code", Customer."Transaction Mode Code");
        ServiceContractHeader.TestField("Bank Account Code", Customer."Preferred Bank Account Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTransactionModeServiceContractHeader()
    var
        ServiceContractHeader: Record "Service Contract Header";
        TransactionMode: Record "Transaction Mode";
    begin
        // Purpose of the test is to validate Transaction Mode Code of Service Contract Header Table.

        // Setup.
        Initialize();
        CreateTransactionMode(TransactionMode, TransactionMode."Account Type"::Customer);
        CreateServiceContractHeader(ServiceContractHeader);

        // Exercise.
        ServiceContractHeader.Validate("Transaction Mode Code", TransactionMode.Code);
        ServiceContractHeader.Modify();

        // Verify.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.TestField("Payment Terms Code", TransactionMode."Payment Terms Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTransactionModeServiceInvoiceHeader()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TransactionMode: Record "Transaction Mode";
    begin
        // Purpose of the test is to validate Transaction Mode Code of Service Invoice Header Table.

        // Setup.
        Initialize();
        CreateTransactionMode(TransactionMode, TransactionMode."Account Type"::Customer);
        CreateServiceInvoiceHeader(ServiceInvoiceHeader);

        // Exercise.
        ServiceInvoiceHeader.Validate("Transaction Mode Code", TransactionMode.Code);
        ServiceInvoiceHeader.Modify();

        // Verify.
        ServiceInvoiceHeader.Get(ServiceInvoiceHeader."No.");
        ServiceInvoiceHeader.TestField("Payment Terms Code", TransactionMode."Payment Terms Code");
        ServiceInvoiceHeader.TestField("Payment Method Code", TransactionMode."Payment Method Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTransactionModeServiceCrMemoHeader()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TransactionMode: Record "Transaction Mode";
    begin
        // Purpose of the test is to validate Transaction Mode Code of Service Cr. Memo Header Table.

        // Setup.
        Initialize();
        CreateTransactionMode(TransactionMode, TransactionMode."Account Type"::Customer);
        CreateServiceCrMemoHeader(ServiceCrMemoHeader);

        // Exercise.
        ServiceCrMemoHeader.Validate("Transaction Mode Code", TransactionMode.Code);
        ServiceCrMemoHeader.Modify();

        // Verify.
        ServiceCrMemoHeader.Get(ServiceCrMemoHeader."No.");
        ServiceCrMemoHeader.TestField("Payment Terms Code", TransactionMode."Payment Terms Code");
        ServiceCrMemoHeader.TestField("Payment Method Code", TransactionMode."Payment Method Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAccountNoGenJournalLineCust()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Account No of Customer of Gen. Journal Line Table.
        Initialize();
        CreateCustomer(Customer);
        OnValidateAccountNoGenJournalLine(
          GenJournalLine."Account Type"::Customer, Customer."No.", Customer."Transaction Mode Code",
          Customer."Preferred Bank Account Code", GenJournalLine."Bal. Account Type"::Customer);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAccountNoGenJournalLineVend()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Account No of Vendor of Gen. Journal Line Table.
        Initialize();
        CreateVendor(Vendor);
        OnValidateAccountNoGenJournalLine(
          GenJournalLine."Account Type"::Vendor, Vendor."No.", Vendor."Transaction Mode Code",
          Vendor."Preferred Bank Account Code", GenJournalLine."Bal. Account Type"::Vendor);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAccountNoGenJournalLineEmpl()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Employee: Record Employee;
    begin
        // Purpose of the test is to validate Account No of Vendor of Gen. Journal Line Table.
        Initialize();
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);
        OnValidateAccountNoGenJournalLine(
          GenJournalLine."Account Type"::Employee, Employee."No.", Employee."Transaction Mode Code",
          CopyStr(Employee."Bank Account No.", 1, MaxStrLen(GenJournalLine."Recipient Bank Account")),
          GenJournalLine."Bal. Account Type"::Employee);
    end;

    local procedure OnValidateAccountNoGenJournalLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; TransactionModeCode: Code[20]; BankAccountCode: Code[20]; BalAccountType: Enum "Gen. Journal Account Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup.
        CreateGenJournalLine(GenJournalLine, AccountType, BalAccountType);

        // Exercise.
        GenJournalLine.Validate("Account No.", AccountNo);
        GenJournalLine.Modify();

        // Verify.
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        GenJournalLine.TestField("Transaction Mode Code", TransactionModeCode);

        if AccountType = GenJournalLine."Account Type"::Employee then
            GenJournalLine.TestField("Recipient Bank Account", AccountNo)
        else
            GenJournalLine.TestField("Recipient Bank Account", BankAccountCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateExportProtocolExportIDReport()
    var
        ExportProtocol: Record "Export Protocol";
        AllObj: Record AllObj;
    begin
        ExportProtocol."Export Object Type" := ExportProtocol."Export Object Type"::Report;
        ExportProtocol.Validate("Export ID", FindObject(AllObj, AllObj."Object Type"::Report));
        Assert.AreEqual(AllObj."Object Name", ExportProtocol."Export Name", ExportProtocol.FieldName("Export Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateExportProtocolExportIDXMLPort()
    var
        ExportProtocol: Record "Export Protocol";
        AllObj: Record AllObj;
    begin
        ExportProtocol."Export Object Type" := ExportProtocol."Export Object Type"::XMLPort;
        ExportProtocol.Validate("Export ID", FindObject(AllObj, AllObj."Object Type"::XMLport));
        Assert.AreEqual(AllObj."Object Name", ExportProtocol."Export Name", ExportProtocol.FieldName("Export Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateExportProtocolNotValidExportID()
    var
        ExportProtocol: Record "Export Protocol";
        AllObj: Record AllObj;
    begin
        ExportProtocol."Export Object Type" := ExportProtocol."Export Object Type"::XMLPort;
        asserterror ExportProtocol.Validate("Export ID", FindObject(AllObj, AllObj."Object Type"::Report));
        Assert.ExpectedError(CannotBeFoundErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTransactionModeGenJournalLineCust()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TransactionMode: Record "Transaction Mode";
    begin
        // Purpose of the test is to validate Transaction Mode Code of Gen. Journal Line Table for Customer.
        OnValidateTransactionModeGenJournalLine(
          GenJournalLine."Account Type"::Customer, GenJournalLine."Bal. Account Type"::Customer, TransactionMode."Account Type"::Customer);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTransactionModeGenJournalLineVend()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TransactionMode: Record "Transaction Mode";
    begin
        // Purpose of the test is to validate Transaction Mode Code of Gen. Journal Line Table for Vendor.
        OnValidateTransactionModeGenJournalLine(
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Bal. Account Type"::Vendor, TransactionMode."Account Type"::Vendor);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTransactionModeGenJournalLineEmpl()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TransactionMode: Record "Transaction Mode";
    begin
        // Purpose of the test is to validate Transaction Mode Code of Gen. Journal Line Table for Employee.
        OnValidateTransactionModeGenJournalLine(
          GenJournalLine."Account Type"::Employee, GenJournalLine."Bal. Account Type"::Employee, TransactionMode."Account Type"::Employee);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTransactionModeGenJournalLineGLAndCust()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TransactionMode: Record "Transaction Mode";
    begin
        // Purpose of the test is to validate Transaction Mode Code of Gen. Journal Line Table for G/L Account and Customer.
        OnValidateTransactionModeGenJournalLine(
          GenJournalLine."Account Type"::"G/L Account",
          GenJournalLine."Bal. Account Type"::Customer, TransactionMode."Account Type"::Customer);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTransactionModeGenJournalLineGLAndVend()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TransactionMode: Record "Transaction Mode";
    begin
        // Purpose of the test is to validate Transaction Mode Code of Gen. Journal Line Table for G/L Account and Vendor.
        OnValidateTransactionModeGenJournalLine(
          GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Bal. Account Type"::Vendor,
          TransactionMode."Account Type"::Vendor);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTransactionModeGenJournalLineGLAndEmpl()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TransactionMode: Record "Transaction Mode";
    begin
        // Purpose of the test is to validate Transaction Mode Code of Gen. Journal Line Table for G/L Account and Employee.
        OnValidateTransactionModeGenJournalLine(
          GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Bal. Account Type"::Employee,
          TransactionMode."Account Type"::Employee);
    end;

    [TransactionModel(TransactionModel::AutoRollback)]
    local procedure OnValidateTransactionModeGenJournalLine(AccountType: Enum "Gen. Journal Account Type"; BalAccountType: Enum "Gen. Journal Account Type"; TransactionModeAccountType: Option)
    var
        GenJournalLine: Record "Gen. Journal Line";
        TransactionMode: Record "Transaction Mode";
    begin
        // Setup.
        Initialize();
        CreateTransactionMode(TransactionMode, TransactionModeAccountType);
        CreateGenJournalLine(GenJournalLine, AccountType, BalAccountType);

        // Exercise.
        GenJournalLine.Validate("Transaction Mode Code", TransactionMode.Code);
        GenJournalLine.Modify();

        // Verify.
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        GenJournalLine.TestField("Payment Terms Code", TransactionMode."Payment Terms Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTransactionModeGenJournalLineError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TransactionMode: Record "Transaction Mode";
    begin
        // Purpose of the test is to validate Transaction Mode Code of Gen. Journal Line Table for G/L Account and G/L Account.

        // Setup.
        Initialize();
        CreateTransactionMode(TransactionMode, TransactionMode."Account Type"::Vendor);
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Bal. Account Type"::"G/L Account");

        // Exercise.
        asserterror GenJournalLine.Validate("Transaction Mode Code", TransactionMode.Code);

        // Verify: Verify error message Transaction Mode Code can only be filled in when Account Type Bal. Account Type is equal to Customer or Vendor.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PaymentHistoryGenerateFileName()
    var
        ExportProtocol: Record "Export Protocol";
        PaymentHistory: Record "Payment History";
        FileName: Text;
    begin
        MockExportProtocol(ExportProtocol, '%1.xml');

        PaymentHistory.Init();
        PaymentHistory."Export Protocol" := ExportProtocol.Code;
        PaymentHistory."File on Disk" := '';
        PaymentHistory.Insert();

        FileName := PaymentHistory.GenerateExportfilename(false);

        Assert.AreEqual(GetExportFileName(1), FileName, PaymentHistory.FieldName("File on Disk"));
        Assert.AreEqual(FileName, PaymentHistory."File on Disk", PaymentHistory.FieldName("File on Disk"));
        Assert.AreEqual(UserId, PaymentHistory."Sent By", PaymentHistory.FieldName("Sent By"));
        Assert.AreEqual(Today, PaymentHistory."Sent On", PaymentHistory.FieldName("Sent On"));
        Assert.AreEqual(1, PaymentHistory."Day Serial Nr.", PaymentHistory.FieldName("Day Serial Nr."));
        Assert.AreEqual(PaymentHistory.Status::New, PaymentHistory.Status, PaymentHistory.FieldName(Status));
        Assert.AreEqual(0, PaymentHistory."Number of Copies", PaymentHistory.FieldName("Number of Copies"));
        Assert.IsTrue(PaymentHistory.Export, PaymentHistory.FieldName(Export));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PaymentHistoryGenerateFileNameTwiceADay()
    var
        ExportProtocol: Record "Export Protocol";
        PaymentHistory: Record "Payment History";
        OldPaymentHistory: Record "Payment History";
    begin
        MockExportProtocol(ExportProtocol, '%1.xml');

        PaymentHistory.Init();
        PaymentHistory."Export Protocol" := ExportProtocol.Code;
        PaymentHistory."File on Disk" := LibraryUTUtility.GetNewCode();
        PaymentHistory."Sent On" := Today;
        PaymentHistory."Sent By" := LibraryUTUtility.GetNewCode();
        PaymentHistory."Day Serial Nr." := 2;
        PaymentHistory.Status := PaymentHistory.Status::Transmitted;
        PaymentHistory.Insert();
        OldPaymentHistory := PaymentHistory;

        PaymentHistory.GenerateExportfilename(true);

        Assert.AreNotEqual(OldPaymentHistory."File on Disk", PaymentHistory."File on Disk", PaymentHistory.FieldName("File on Disk"));
        Assert.AreEqual(
          OldPaymentHistory."Day Serial Nr." + 1, PaymentHistory."Day Serial Nr.", PaymentHistory.FieldName("Day Serial Nr."));
        Assert.AreEqual(
          OldPaymentHistory."Number of Copies", PaymentHistory."Number of Copies", PaymentHistory.FieldName("Number of Copies"));
        Assert.IsTrue(PaymentHistory.Export, PaymentHistory.FieldName(Export));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PaymentHistoryReGenerateFileName()
    var
        ExportProtocol: Record "Export Protocol";
        PaymentHistory: Record "Payment History";
        OldPaymentHistory: Record "Payment History";
    begin
        MockExportProtocol(ExportProtocol, '%1.xml');

        PaymentHistory.Init();
        PaymentHistory."Export Protocol" := ExportProtocol.Code;
        PaymentHistory."File on Disk" := LibraryUTUtility.GetNewCode();
        PaymentHistory."Sent On" := Today - 1;
        PaymentHistory."Sent By" := LibraryUTUtility.GetNewCode();
        PaymentHistory.Status := PaymentHistory.Status::Transmitted;
        PaymentHistory.Insert();
        OldPaymentHistory := PaymentHistory;

        PaymentHistory.GenerateExportfilename(false);

        Assert.AreEqual(OldPaymentHistory."File on Disk", PaymentHistory."File on Disk", PaymentHistory.FieldName("File on Disk"));
        Assert.AreEqual(OldPaymentHistory."Sent By", PaymentHistory."Sent By", PaymentHistory.FieldName("Sent By"));
        Assert.AreEqual(OldPaymentHistory."Sent On", PaymentHistory."Sent On", PaymentHistory.FieldName("Sent On"));
        Assert.AreEqual(OldPaymentHistory.Status, PaymentHistory.Status, PaymentHistory.FieldName(Status));
        Assert.AreEqual(
          OldPaymentHistory."Number of Copies" + 1, PaymentHistory."Number of Copies", PaymentHistory.FieldName("Number of Copies"));
        Assert.IsTrue(PaymentHistory.Export, PaymentHistory.FieldName(Export));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentHistoryGenerateFileNameVerifyFormatDDMMSS()
    var
        ExportProtocol: Record "Export Protocol";
        PaymentHistory: Record "Payment History";
        DaySerial: Integer;
    begin
        // [SCENARIO 121894] Verify PaymentHistory.GenerateExportfilename() format DDMMSS, where DD - TODAY's day, MM - TODAY's month, SS - day serial number
        MockExportProtocol(ExportProtocol, '%1.xml');
        DaySerial := LibraryRandom.RandIntInRange(10, 98); // 2-digits value

        // [GIVEN] Payment History with "Sent On" = TODAY, "Day Serial Nr." = N (2-digits value)
        PaymentHistory.Init();
        PaymentHistory."Export Protocol" := ExportProtocol.Code;
        PaymentHistory."Sent On" := Today;
        PaymentHistory."Day Serial Nr." := DaySerial;
        PaymentHistory.Insert();

        // [WHEN] PaymentHistory.GenerateExportfilename()
        // [THEN] Generated File name consits of 'DDMMSS' text, where DD - TODAY's day, MM - TODAY's month, SS = (N + 1)
        Assert.AreEqual(
          GetExportFileName(DaySerial + 1),
          PaymentHistory.GenerateExportfilename(true),
          PaymentHistory.FieldName("File on Disk"));
    end;

    local procedure Initialize()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT TAB Telebank");
        GenJournalLine.DeleteAll();
        ExportErrorsPerLine := 3;
        LinesPerPaymentHistory := 3;
    end;

    local procedure InsertCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; PaymentHistoryLine: Record "Payment History Line"): Code[20]
    begin
        PostSalesCreditMemo(CustLedgEntry, PaymentHistoryLine."Account No.", LibraryRandom.RandDec(1000, 2));
        CreateDetailLine(PaymentHistoryLine, CustLedgEntry."Entry No.");
        exit(CustLedgEntry."Document No.");
    end;

    local procedure InsertVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; PaymentHistoryLine: Record "Payment History Line"): Code[35]
    begin
        PostPurchaseInvoice(VendLedgEntry, PaymentHistoryLine."Account No.", LibraryRandom.RandDec(1000, 2));
        CreateDetailLine(PaymentHistoryLine, VendLedgEntry."Entry No.");
        exit(VendLedgEntry."External Document No.");
    end;

    local procedure InsertEmplLedgEntry(var EmplLedgEntry: Record "Employee Ledger Entry"; PaymentHistoryLine: Record "Payment History Line"): Code[20]
    begin
        PostEmployeeExpense(EmplLedgEntry, PaymentHistoryLine."Account No.", LibraryRandom.RandDec(1000, 2));
        CreateDetailLine(PaymentHistoryLine, EmplLedgEntry."Entry No.");
        exit(EmplLedgEntry."Document No.");
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    var
        TransactionMode: Record "Transaction Mode";
    begin
        CreateTransactionMode(TransactionMode, TransactionMode."Account Type"::Customer);
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer."Preferred Bank Account Code" := CreateCustomerBankAccount(Customer."No.");
        Customer."Transaction Mode Code" := TransactionMode.Code;
        Customer.Insert();
    end;

    local procedure CreateCustomerBankAccount(CustomerNo: Code[20]): Code[10]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount."Customer No." := CustomerNo;
        CustomerBankAccount.Code := LibraryUTUtility.GetNewCode10();
        CustomerBankAccount.Insert();
        exit(CustomerBankAccount.Code);
    end;

    local procedure CreateDetailLine(PaymentHistoryLine: Record "Payment History Line"; EntryNo: Integer)
    var
        DetailLine: Record "Detail Line";
    begin
        DetailLine.Init();
        DetailLine."Transaction No." := EntryNo;
        DetailLine."Our Bank" := PaymentHistoryLine."Our Bank";
        DetailLine.Status := DetailLine.Status::Posted;
        DetailLine."Connect Batches" := PaymentHistoryLine."Run No.";
        DetailLine."Connect Lines" := PaymentHistoryLine."Line No.";
        DetailLine."Account Type" := PaymentHistoryLine."Account Type";
        DetailLine."Serial No. (Entry)" := EntryNo;
        DetailLine.Insert();
    end;

    local procedure CreateExportProtocol(): Code[20]
    var
        ExportProtocol: Record "Export Protocol";
    begin
        ExportProtocol.Code := LibraryUTUtility.GetNewCode();
        ExportProtocol."Check ID" := CODEUNIT::"Check BBV";
        ExportProtocol."Export ID" := REPORT::"Export BBV";
        ExportProtocol."Docket ID" := REPORT::Docket;
        ExportProtocol.Insert();
        exit(ExportProtocol.Code);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; BalAccountType: Enum "Gen. Journal Account Type")
    begin
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Bal. Account Type" := BalAccountType;
        GenJournalLine.Insert();
    end;

    local procedure CreatePaymentHistory(var PaymentHistory: Record "Payment History")
    begin
        PaymentHistory.Init();
        PaymentHistory."Our Bank" := PadStr('', 10, '0') + LibraryUTUtility.GetNewCode10();
        PaymentHistory."Run No." := LibraryUTUtility.GetNewCode10();
        PaymentHistory.Insert();
    end;

    local procedure CreatePaymentHistories(PaymentHistory: Record "Payment History")
    var
        PaymentHistoryLine: Record "Payment History Line";
    begin
        PaymentHistory."Run No." := LibraryUTUtility.GetNewCode10();
        PaymentHistory.Insert();
        CreatePaymentHistoryLinesWithExportErrors(PaymentHistory, PaymentHistoryLine);

        CreatePaymentHistory(PaymentHistory);
        CreatePaymentHistoryLinesWithExportErrors(PaymentHistory, PaymentHistoryLine);
    end;

    local procedure CreatePaymentHistoryLinesWithExportErrors(PaymentHistory: Record "Payment History"; var PaymentHistoryLine: Record "Payment History Line")
    var
        GenJnlLine: Record "Gen. Journal Line";
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        i: Integer;
        j: Integer;
    begin
        PaymentHistoryLine.Init();
        PaymentHistoryLine."Our Bank" := PaymentHistory."Our Bank";
        PaymentHistoryLine."Run No." := PaymentHistory."Run No.";
        PaymentHistoryLine.Status := PaymentHistoryLine.Status::Rejected;
        for i := 1 to LinesPerPaymentHistory do begin
            PaymentHistoryLine."Line No." += 1;
            PaymentHistoryLine.Insert();

            for j := 1 to ExportErrorsPerLine do begin
                GenJnlLine.Init();
                GenJnlLine."Journal Template Name" := '';
                GenJnlLine."Journal Batch Name" := '';
                GenJnlLine."Bal. Account No." := PaymentHistoryLine."Our Bank";
                GenJnlLine."Document No." := PaymentHistoryLine."Run No.";
                GenJnlLine."Line No." := PaymentHistoryLine."Line No.";
                PaymentJnlExportErrorText.CreateNew(GenJnlLine, '', '', '');
            end;
        end;
    end;

    local procedure CreateServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader."Contract Type" := ServiceContractHeader."Contract Type"::Quote;
        ServiceContractHeader."Contract No." := LibraryUTUtility.GetNewCode();
        ServiceContractHeader.Insert();
    end;

    local procedure CreateServiceCrMemoHeader(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        ServiceCrMemoHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceCrMemoHeader.Insert();
    end;

    local procedure CreateServiceInvoiceHeader(var ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        ServiceInvoiceHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceInvoiceHeader.Insert();
    end;

    local procedure CreateTransactionMode(var TransactionMode: Record "Transaction Mode"; AccountType: Option)
    var
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Code := LibraryUTUtility.GetNewCode10();
        PaymentTerms.Insert();
        PaymentMethod.Code := LibraryUTUtility.GetNewCode10();
        PaymentMethod.Insert();
        TransactionMode."Account Type" := AccountType;
        TransactionMode.Code := LibraryUTUtility.GetNewCode();
        TransactionMode."Export Protocol" := CreateExportProtocol();
        TransactionMode."Payment Terms Code" := PaymentTerms.Code;
        TransactionMode."Payment Method Code" := PaymentMethod.Code;
        TransactionMode.Insert();
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    var
        TransactionMode: Record "Transaction Mode";
    begin
        CreateTransactionMode(TransactionMode, TransactionMode."Account Type"::Vendor);
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor."Preferred Bank Account Code" := CreateVendorBankAccount(Vendor."No.");
        Vendor."Transaction Mode Code" := TransactionMode.Code;
        Vendor.Insert();
    end;

    local procedure CreateVendorBankAccount(VendorNo: Code[20]): Code[10]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount."Vendor No." := VendorNo;
        VendorBankAccount.Code := LibraryUTUtility.GetNewCode10();
        VendorBankAccount.Insert();
        exit(VendorBankAccount.Code);
    end;

    local procedure MockExportProtocol(var ExportProtocol: Record "Export Protocol"; DefaultFileNames: Text[250])
    begin
        ExportProtocol.Init();
        ExportProtocol.Code := LibraryUTUtility.GetNewCode();
        ExportProtocol."Default File Names" := DefaultFileNames;
        ExportProtocol.Insert();
    end;

    local procedure GetExportFileName(DaySerial: Integer): Text
    begin
        exit(StrSubstNo('%1', Date2DMY(Today, 1) * 10000 + Date2DMY(Today, 2) * 100 + (DaySerial mod 100)) + '.xml');
    end;

    local procedure FindObject(var AllObj: Record AllObj; Type: Option): Integer
    var
        OtherTypeAllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", Type);
        AllObj.FindSet();
        repeat
            OtherTypeAllObj.SetFilter("Object Type", '<>%1', Type);
            OtherTypeAllObj.SetRange("Object ID", AllObj."Object ID");
        until (AllObj.Next() = 0) or OtherTypeAllObj.IsEmpty();
        exit(AllObj."Object ID");
    end;

    local procedure PostDocument(DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; LineAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        GenJournalLine.Init();
        GenJournalLine.Validate("Posting Date", Today);
        GenJournalLine.Validate("Document Type", DocumentType);
        GenJournalLine.Validate("Account Type", AccountType);
        GenJournalLine.Validate("Account No.", AccountNo);
        GenJournalLine.Validate(Amount, -LineAmount);
        GenJournalLine.Validate(
          "Document No.", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"));
        GenJournalLine.Validate("External Document No.", LibraryUtility.GenerateRandomText(MaxStrLen(GenJournalLine."External Document No.")));
        // Unused but required for vendor posting.
        GenJournalLine.Validate("Source Code", LibraryERM.FindGeneralJournalSourceCode());
        // Unused but required for AU, NZ builds
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::Customer then
            GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale)
        else
            GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        LibraryERM.FindGLAccount(GLAccount);
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");

        GenJnlPostLine.RunWithCheck(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure PostPurchaseInvoice(var VendLedgEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        DocumentNo := PostDocument(GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        VendLedgEntry.SetRange("Document No.", DocumentNo);
        VendLedgEntry.FindLast();
    end;

    local procedure PostEmployeeExpense(var EmplLedgEntry: Record "Employee Ledger Entry"; EmployeeNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        DocumentNo := PostDocument(GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Employee, EmployeeNo, Amount);
        EmplLedgEntry.SetRange("Document No.", DocumentNo);
        EmplLedgEntry.FindLast();
    end;

    local procedure PostSalesCreditMemo(var CustLedgEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        DocumentNo :=
          PostDocument(GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        CustLedgEntry.SetRange("Document No.", DocumentNo);
        CustLedgEntry.FindLast();
    end;

    local procedure VerifyAppliedDocNoList(PaymentHistoryLine: Record "Payment History Line"; DocumentNo: array[2] of Code[35])
    var
        Delimiter: Text[2];
        ExpectedList: Text;
        List: Text;
        TotalLen: Integer;
    begin
        Delimiter := ', ';
        ExpectedList := DocumentNo[1] + Delimiter + DocumentNo[2];
        TotalLen := StrLen(ExpectedList);

        List := PaymentHistoryLine.GetAppliedDocNoList(TotalLen);
        // 'docno000001, docno000002|'
        Assert.AreEqual(ExpectedList, List, AppliedDocNoListErr);

        List := PaymentHistoryLine.GetAppliedDocNoList(TotalLen + 1);
        // 'docno000001, docno000002 |'
        Assert.AreEqual(ExpectedList, List, AppliedDocNoListErr);

        List := PaymentHistoryLine.GetAppliedDocNoList(0);
        // '|docno000001, docno000002'
        Assert.AreEqual(ExpectedList, List, AppliedDocNoListErr);

        List := PaymentHistoryLine.GetAppliedDocNoList(-1);
        // | 'docno000001, docno000002'
        Assert.AreEqual(ExpectedList, List, AppliedDocNoListErr);

        List := PaymentHistoryLine.GetAppliedDocNoList(1);
        // ' |docno000001, docno000002'
        Assert.AreEqual(' ' + ExpectedList, List, AppliedDocNoListErr);

        List := PaymentHistoryLine.GetAppliedDocNoList(TotalLen - 1);
        // 'docno000001           |docno000002'
        Assert.AreEqual(DocumentNo[1], DelChr(CopyStr(List, 1, TotalLen - 1)), AppliedDocNoListErr);
        Assert.AreEqual(DocumentNo[2], DelChr(CopyStr(List, TotalLen)), AppliedDocNoListErr);
    end;

    local procedure VerifyNoExportErrors(DeletedPaymentHistoryLine: Record "Payment History Line")
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.Reset();
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", DeletedPaymentHistoryLine."Our Bank");
        PaymentJnlExportErrorText.SetRange("Document No.", DeletedPaymentHistoryLine."Run No.");
        if DeletedPaymentHistoryLine."Line No." <> 0 then
            PaymentJnlExportErrorText.SetRange("Journal Line No.", DeletedPaymentHistoryLine."Line No.");
        Assert.AreEqual(0, PaymentJnlExportErrorText.Count, 'No error lines expected linked to deleted line');

        if DeletedPaymentHistoryLine."Line No." <> 0 then begin
            PaymentJnlExportErrorText.Reset();
            PaymentJnlExportErrorText.SetRange("Journal Batch Name", DeletedPaymentHistoryLine."Our Bank");
            PaymentJnlExportErrorText.SetRange("Document No.", DeletedPaymentHistoryLine."Run No.");
            PaymentJnlExportErrorText.SetFilter("Journal Line No.", '<>%1', DeletedPaymentHistoryLine."Line No.");
            Assert.AreEqual(
              (LinesPerPaymentHistory - 1) * ExportErrorsPerLine, PaymentJnlExportErrorText.Count,
              'Wrong Error Text count for same Run No.');
        end;

        PaymentJnlExportErrorText.Reset();
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", DeletedPaymentHistoryLine."Our Bank");
        PaymentJnlExportErrorText.SetFilter("Document No.", '<>%1', DeletedPaymentHistoryLine."Run No.");
        Assert.AreEqual(
          LinesPerPaymentHistory * ExportErrorsPerLine, PaymentJnlExportErrorText.Count, 'Wrong Error Text count for same Our Bank');

        PaymentJnlExportErrorText.Reset();
        PaymentJnlExportErrorText.SetFilter("Journal Batch Name", '<>%1', DeletedPaymentHistoryLine."Our Bank");
        Assert.AreEqual(
          LinesPerPaymentHistory * ExportErrorsPerLine, PaymentJnlExportErrorText.Count, 'Wrong Error Text count for different Our Bank');
    end;
}

