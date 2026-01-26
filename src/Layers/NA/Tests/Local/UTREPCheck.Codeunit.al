codeunit 141002 "UT REP Check"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Check printing]
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CheckTextCap: Label 'CheckNoText';
        DialogErr: Label 'Dialog';
        PostingDescriptionCap: Label 'PostingDesc';
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        WrongCheckAmountErr: Label 'Check Amount value is incorrect';
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryUtility: Codeunit "Library - Utility";
        RecordNotFoundErr: Label '%1 was not found.', Comment = 'Gen. Journal Line was not found.';
        RestrictionRecordFoundErr: Label 'Restricted Record for %1 was found.', Comment = 'Restricted Record for Gen. Journal Line: GENERAL,GUAAAAABEE,20000 was found.';
        FormatNoTextSuccessMsg: Label 'FormatNoText should succeed for amount %1.', Comment = 'Amount';
        AndCentsInNoText2Msg: Label 'Formatted amount should contain "%1" in NoText[2]', Comment = 'Cents Value';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordAmountDecimalCheckError10411()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAcc: Record "Vendor Bank Account";
        CheckLedgEntry: Record "Check Ledger Entry";
        VendorNo: Code[20];
        ReportedAmount: Text;
        CurrencySymbol: Code[5];
    begin
        // [FEATURE] [Check printing]
        // [SCENARIO] Amount is reported without decimal part repeated twice by report Check (Stub/Check/Stub)

        // [GIVEN] Payment Journal Line to Vendor where Amount = 100
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreateVendorBankAccount(VendorBankAcc, VendorNo);
        // [GIVEN] Rounding Precision for Currency used for Payment is 0.01
        VendorBankAcc.Validate("Currency Code", CreateCurrencyWithRoundingPrecision(0.01));
        VendorBankAcc.Modify(true);

        CreateComputerCheckPmtLine(
              GenJournalLine, VendorNo, 100, GenJournalLine."Document Type"::Payment,
              GenJournalLine."Account Type"::Vendor, VendorBankAcc."Currency Code");

        CheckLedgEntry.Init();
        CheckLedgEntry.Amount := GenJournalLine.Amount;
        // [WHEN] Getting Check Amount as in 10411 "Check (Stub/Check/Stub)" Report
        ReportedAmount := CheckLedgEntry.GetCheckAmountText(GenJournalLine."Currency Code", CurrencySymbol);

        // [THEN] Reported Check Amount = 100.00
        VerifyReportedCheckAmount(GenJournalLine, ReportedAmount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordAmountDecimalCheckError10401()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAcc: Record "Vendor Bank Account";
        CheckLedgEntry: Record "Check Ledger Entry";
        VendorNo: Code[20];
        CurrencySymbol: Code[5];
        ReportedAmount: Text;
    begin
        // [FEATURE] [Check printing]
        // [SCENARIO] Amount is reported without decimal part repeated twice by report Check (Stub/Stub/Check)

        // [GIVEN] Payment Journal Line to Vendor where Amount = 100
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreateVendorBankAccount(VendorBankAcc, VendorNo);
        // [GIVEN] Rounding Precision for Currency used for Payment is 0.1
        VendorBankAcc.Validate("Currency Code", CreateCurrencyWithRoundingPrecision(0.1));
        VendorBankAcc.Modify(true);

        CreateComputerCheckPmtLine(
              GenJournalLine, VendorNo, 100, GenJournalLine."Document Type"::Payment,
              GenJournalLine."Account Type"::Vendor, VendorBankAcc."Currency Code");

        CheckLedgEntry.Init();
        CheckLedgEntry.Amount := GenJournalLine.Amount;
        // [WHEN] Getting Check Amount as in 10401 "Check (Stub/Stub/Check)" Report
        ReportedAmount := CheckLedgEntry.GetCheckAmountText(GenJournalLine."Currency Code", CurrencySymbol);

        // [THEN] Reported Check Amount = 100.0
        VerifyReportedCheckAmount(GenJournalLine, ReportedAmount);
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccountCheckDateFormatCheckError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 1401 - Check.
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeGLAccountCheck(
          BankAccount."Check Date Format", BankAccount."Bank Communication", REPORT::Check);  // Default value (blank) use for Check Date Format and Bank Communication.
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccountBankCommunicationCheckError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 1401 - Check.
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeGLAccountCheck(
          LibraryRandom.RandIntInRange(1, 3), BankAccount."Bank Communication"::"S Spanish", REPORT::Check);  // Check Date Format- option Range 1 to 3 and Bank Communication -S Spanish.
    end;

    [Test]
    [HandlerFunctions('ThreeChecksRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccountCheckDateFormat3ChecksError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10413 - Three Checks per Page.
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeGLAccountCheck(
          BankAccount."Check Date Format", BankAccount."Bank Communication", REPORT::"Three Checks per Page");  // Default value (blank) use for Check Date Format and Bank Communication.
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccCheckDateFormatStubCheckError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeGLAccountCheck(
          BankAccount."Check Date Format", BankAccount."Bank Communication", REPORT::"Check (Stub/Stub/Check)");  // Default value (blank) use for Check Date Format and Bank Communication.
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccBankCommunicationStubCheckError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeGLAccountCheck(
          LibraryRandom.RandIntInRange(1, 3), BankAccount."Bank Communication"::"S Spanish", REPORT::"Check (Stub/Stub/Check)");  // Check Date Format- option Range 1 to 3 and Bank Communication -S Spanish.
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccCheckDateFormatCheckStubError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeGLAccountCheck(
          BankAccount."Check Date Format", BankAccount."Bank Communication", REPORT::"Check (Stub/Check/Stub)");  // Default value (blank) use for Check Date Format and Bank Communication.
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccBankCommunicationCheckStubError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeGLAccountCheck(
          LibraryRandom.RandIntInRange(1, 3), BankAccount."Bank Communication"::"S Spanish", REPORT::"Check (Stub/Check/Stub)");  // Check Date Format- option Range 1 to 3 and Bank Communication -S Spanish.
    end;

    local procedure OnAfterGetRecordAccountTypeGLAccountCheck(CheckDateFormat: Option; BankCommunication: Option; ReportID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
    begin
        // Create Bank Account and General Journal line with Account Type G/L Account.
        CreateBankAccount(BankAccount, CheckDateFormat, BankCommunication);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::"G/L Account", '', BankAccount."No.");

        // Exercise.
        asserterror REPORT.Run(ReportID);  // Invoke RequestPageHandler.

        // Verify: Verify Error Code, Actual error - You cannot use the <blank> Check Date Format option with a Canadian style check. Please check Bank Account or
        // You cannot use the Spanish Bank Communication option with a Canadian style check. Please check Bank Account.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerCheckDateFormatCheckError()
    var
        Customer: Record Customer;
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 1401 - Check.
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeCustomerCheck(
          Customer."Check Date Format", Customer."Bank Communication", REPORT::Check);  // Default value (blank) use for Check Date Format and Bank Communication.
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerBankCommunicationCheckError()
    var
        Customer: Record Customer;
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 1401 - Check.
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeCustomerCheck(
          LibraryRandom.RandIntInRange(1, 3), Customer."Bank Communication"::"S Spanish", REPORT::Check);  // Check Date Format- option Range 1 to 3 and Bank Communication -S Spanish.
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerCheckDateFormatStubCheckError()
    var
        Customer: Record Customer;
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeCustomerCheck(
          Customer."Check Date Format", Customer."Bank Communication", REPORT::"Check (Stub/Stub/Check)");  // Default value (blank) use for Check Date Format and Bank Communication.
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerBankCommunicationStubCheckError()
    var
        Customer: Record Customer;
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeCustomerCheck(
          LibraryRandom.RandIntInRange(1, 3), Customer."Bank Communication"::"S Spanish", REPORT::"Check (Stub/Stub/Check)");  // Check Date Format- option Range 1 to 3 and Bank Communication -S Spanish.
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerCheckDateFormatCheckStubError()
    var
        Customer: Record Customer;
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeCustomerCheck(
          Customer."Check Date Format", Customer."Bank Communication", REPORT::"Check (Stub/Check/Stub)");  // Default value (blank) use for Check Date Format and Bank Communication.
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerBankCommunicationCheckStubError()
    var
        Customer: Record Customer;
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeCustomerCheck(
          LibraryRandom.RandIntInRange(1, 3), Customer."Bank Communication"::"S Spanish", REPORT::"Check (Stub/Check/Stub)");  // Check Date Format- option Range 1 to 3 and Bank Communication -S Spanish.
    end;

    [Test]
    [HandlerFunctions('ThreeChecksRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerCheckDateFormat3ChecksError()
    var
        Customer: Record Customer;
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10413 - Three Checks per Page.
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeCustomerCheck(
          Customer."Check Date Format", Customer."Bank Communication", REPORT::"Three Checks per Page");  // Default value (blank) use for Check Date Format and Bank Communication.
    end;

    local procedure OnAfterGetRecordAccountTypeCustomerCheck(CheckDateFormat: Option; BankCommunication: Option; ReportID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
    begin
        // Create Customer, Bank Account and General Journal line with Account Type Customer.
        CreateCustomer(Customer, CheckDateFormat, BankCommunication);
        CreateBankAccount(BankAccount, BankAccount."Check Date Format", BankAccount."Bank Communication");
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", BankAccount."No.");

        // Exercise.
        asserterror REPORT.Run(ReportID);  // Invoke RequestPageHandler.

        // Verify: Verify Error Code, Actual error - You cannot use the <blank> Check Date Format option with a Canadian style check. Please check Customer or
        // You cannot use the Spanish Bank Communication option with a Canadian style check. Please check Customer.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorCheckDateFormatCheckError()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 1401 - Check.
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeVendorCheck(
          Vendor."Check Date Format", Vendor."Bank Communication", REPORT::Check);  // Default value (blank) use for Check Date Format and Bank Communication.
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorBankCommunicationCheckError()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 1401 - Check.
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeVendorCheck(
          LibraryRandom.RandIntInRange(1, 3), Vendor."Bank Communication"::"S Spanish", REPORT::Check);  // Check Date Format- option Range 1 to 3 and Bank Communication -S Spanish.
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorCheckDateFormatStubCheckError()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeVendorCheck(
          Vendor."Check Date Format", Vendor."Bank Communication", REPORT::"Check (Stub/Stub/Check)");  // Default value (blank) use for Check Date Format and Bank Communication.
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorBankCommunicationStubCheckError()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeVendorCheck(
          LibraryRandom.RandIntInRange(1, 3), Vendor."Bank Communication"::"S Spanish", REPORT::"Check (Stub/Stub/Check)");  // Check Date Format- option Range 1 to 3 and Bank Communication -S Spanish.
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorCheckDateFormatCheckStubError()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeVendorCheck(
          Vendor."Check Date Format", Vendor."Bank Communication", REPORT::"Check (Stub/Check/Stub)");  // Default value (blank) use for Check Date Format and Bank Communication.
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorBankCommunicationCheckStubError()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeVendorCheck(
          LibraryRandom.RandIntInRange(1, 3), Vendor."Bank Communication"::"S Spanish", REPORT::"Check (Stub/Check/Stub)");  // Check Date Format- option Range 1 to 3 and Bank Communication -S Spanish.
    end;

    [Test]
    [HandlerFunctions('ThreeChecksRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendorCheckDateFormat3ChecksError()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10413 - Three Checks per Page.
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeVendorCheck(
          Vendor."Check Date Format", Vendor."Bank Communication", REPORT::"Three Checks per Page");  // Default value (blank) use for Check Date Format and Bank Communication.
    end;

    local procedure OnAfterGetRecordAccountTypeVendorCheck(CheckDateFormat: Option; BankCommunication: Option; ReportID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
    begin
        // Create Vendor, Bank Account and General Journal line with Account Type Vendor.
        CreateVendor(Vendor, CheckDateFormat, BankCommunication);
        CreateBankAccount(BankAccount, BankAccount."Check Date Format", BankAccount."Bank Communication");
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", BankAccount."No.");

        // Exercise.
        asserterror REPORT.Run(ReportID);  // Invoke RequestPageHandler.

        // Verify: Verify Error Code, Actual error - You cannot use the <blank> Check Date Format option with a Canadian style check. Please check Vendor or
        // You cannot use the Spanish Bank Communication option with a Canadian style check. Please check Vendor.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccountCheckDateFormatCheckError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 1401 - Check.
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeBankAccountCheck(
          BankAccount."Check Date Format", BankAccount."Bank Communication", REPORT::Check);  // Default value (blank) use for Check Date Format and Bank Communication.
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccountBankCommunicationCheckError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 1401 - Check.
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeBankAccountCheck(
          LibraryRandom.RandIntInRange(1, 3), BankAccount."Bank Communication"::"S Spanish", REPORT::Check);  // Check Date Format- option Range 1 to 3 and Bank Communication -S Spanish.
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccCheckDateFormatStubCheckError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeBankAccountCheck(
          BankAccount."Check Date Format", BankAccount."Bank Communication", REPORT::"Check (Stub/Stub/Check)");  // Default value (blank) use for Check Date Format and Bank Communication.
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccBankCommunicationStubCheckError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeBankAccountCheck(
          LibraryRandom.RandIntInRange(1, 3), BankAccount."Bank Communication"::"S Spanish", REPORT::"Check (Stub/Stub/Check)");  // Check Date Format- option Range 1 to 3 and Bank Communication -S Spanish.
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccCheckDateFormatCheckStubError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeBankAccountCheck(
          BankAccount."Check Date Format", BankAccount."Bank Communication", REPORT::"Check (Stub/Check/Stub)");  // Default value (blank) use for Check Date Format and Bank Communication.
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccBankCommunicationCheckStubError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeBankAccountCheck(
          LibraryRandom.RandIntInRange(1, 3), BankAccount."Bank Communication"::"S Spanish", REPORT::"Check (Stub/Check/Stub)");  // Check Date Format- option Range 1 to 3 and Bank Communication -S Spanish.
    end;

    [Test]
    [HandlerFunctions('ThreeChecksRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccCheckDateFormat3ChecksError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate TestGenJnlLine - OnAfterGetRecord of Report 10413 - Three Checks per Page.
        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypeBankAccountCheck(
          BankAccount."Check Date Format", BankAccount."Bank Communication", REPORT::"Three Checks per Page");  // Default value (blank) use for Check Date Format and Bank Communication.
    end;

    local procedure OnAfterGetRecordAccountTypeBankAccountCheck(CheckDateFormat: Option; BankCommunication: Option; ReportID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
    begin
        // Create Bank Account and General Journal line with Account Type BankAccount.
        CreateBankAccount(BankAccount, CheckDateFormat, BankCommunication);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::"Bank Account", BankAccount."No.", BankAccount."No.");

        // Exercise.
        asserterror REPORT.Run(ReportID);  // Invoke RequestPageHandler.

        // Verify: Verify Error Code, Actual error - You cannot use the <blank> Check Date Format option with a Canadian style check. Please check Bank Account or
        // You cannot use the Spanish Bank Communication option with a Canadian style check. Please check Bank Account.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler,ConfirmHandlerFalse')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportProcessCancelledCheckError()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 1401 - Check.
        // Setup.
        Initialize();
        OnPreReportProcessCancelled(REPORT::Check);
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler,ConfirmHandlerFalse')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportProcessCancelledStubCheckError()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnPreReportProcessCancelled(REPORT::"Check (Stub/Stub/Check)");
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler,ConfirmHandlerFalse')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportProcessCancelledCheckStubkError()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnPreReportProcessCancelled(REPORT::"Check (Stub/Check/Stub)")
    end;

    [Test]
    [HandlerFunctions('ThreeChecksRequestPageHandler,ConfirmHandlerFalse')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportProcessCancelled3ChecksError()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 10413 - Three Checks per Page.
        // Setup.
        Initialize();
        OnPreReportProcessCancelled(REPORT::"Three Checks per Page")
    end;

    local procedure OnPreReportProcessCancelled(ReportID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Create Bank Account, General Journal line and Update Journal Template - Force Document Balance.
        CreateBankAccount(BankAccount, LibraryRandom.RandIntInRange(0, 3), LibraryRandom.RandIntInRange(0, 2));  // Check Date Format - option Range 0 to 3 and Bank Communication - option Range 0 to 2.
        CreateGenJournalLine(GenJournalLine,
            "Gen. Journal Account Type".FromInteger(LibraryRandom.RandIntInRange(0, 5)), BankAccount."No.", BankAccount."No.");  // Account Type - option Range 0 to 5.
        GenJournalTemplate.Get(GenJournalLine."Journal Template Name");
        GenJournalTemplate."Force Doc. Balance" := false;  // Default value is TRUE, updating it as FALSE.
        GenJournalTemplate.Modify();

        // Exercise.
        asserterror REPORT.Run(ReportID);  // Invoke RequestPageHandler.

        // Verify: Verify Error Code, Actual error - Process cancelled at user request.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVoidGenJnlLineLastStubCheckError()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnPreDataItem Trigger of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnPreDataItemVoidGenJnlLineLastCheck(REPORT::"Check (Stub/Stub/Check)");
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVoidGenJnlLineLastCheckStubError()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnPreDataItem Trigger of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnPreDataItemVoidGenJnlLineLastCheck(REPORT::"Check (Stub/Check/Stub)");
    end;

    [Test]
    [HandlerFunctions('ThreeChecksRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVoidGenJnlLineLast3ChecksError()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnPreDataItem Trigger of Report 10413 - Three Checks per Page.
        // Setup.
        Initialize();
        OnPreDataItemVoidGenJnlLineLastCheck(REPORT::"Three Checks per Page");
    end;

    local procedure OnPreDataItemVoidGenJnlLineLastCheck(ReportID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create General Journal Line.
        LibraryVariableStorage.Enqueue('');  // Enqueue blank value for Bank Account on handler - StubCheckRequestPageHandler or CheckStubRequestPageHandler or ThreeChecksRequestPageHandler.
        CreateGenJournalLine(GenJournalLine,
            "Gen. Journal Account Type".FromInteger(LibraryRandom.RandIntInRange(0, 5)), '', '');  // // Account Type - option Range 0 to 5 and blank value for Account number and Balance Account number.

        // Exercise.
        asserterror REPORT.Run(ReportID);  // Invoke RequestPageHandler.

        // Verify: Verify Error Code, Actual error - Last Check No. must be filled in.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVoidGenJnlLineAtLeastOneDigitCheckError()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnPreDataItem Trigger of Report 1401 - Check.
        // Setup.
        Initialize();
        OnPreDataItemVoidGenJnlLineAtLeastOneDigit(REPORT::Check);
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVoidGenJnlLineAtLeastOneDigitStubCheckError()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnPreDataItem Trigger of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnPreDataItemVoidGenJnlLineAtLeastOneDigit(REPORT::"Check (Stub/Stub/Check)");
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVoidGenJnlLineAtLeastOneDigitCheckStubError()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnPreDataItem Trigger of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnPreDataItemVoidGenJnlLineAtLeastOneDigit(REPORT::"Check (Stub/Check/Stub)");
    end;

    [Test]
    [HandlerFunctions('ThreeChecksRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVoidGenJnlLineAtLeastOneDigit3ChecksError()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnPreDataItem Trigger of Report 10413 - Three Checks per Page.
        // Setup.
        Initialize();
        OnPreDataItemVoidGenJnlLineAtLeastOneDigit(REPORT::"Three Checks per Page");
    end;

    local procedure OnPreDataItemVoidGenJnlLineAtLeastOneDigit(ReportID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
    begin
        // Create Bank Account, General Journal line and Update Last Check number without having digits.
        CreateBankAccount(BankAccount, LibraryRandom.RandIntInRange(0, 3), LibraryRandom.RandIntInRange(0, 2));  // Check Date Format - option Range 0 to 3 and Bank Communication - option Range 0 to 2.
        BankAccount."Last Check No." := BankAccount.TableCaption();  // Using Last check Number without having digits.
        BankAccount.Modify();
        CreateGenJournalLine(
            GenJournalLine, "Gen. Journal Account Type".FromInteger(LibraryRandom.RandIntInRange(0, 5)),
            BankAccount."No.", BankAccount."No.");  // Account Type - option Range 0 to 5.

        // Exercise.
        asserterror REPORT.Run(ReportID);  // Invoke RequestPageHandler.

        // Verify: Verify Error Code, Actual error - Last Check No. must include at least one digit, so that it can be incremented.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('DocumentNoStubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVoidGenJnlLineFilterStubCheckError()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnPreDataItem Trigger of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnPreDataItemVoidGenJnlLineWithDocumentNo(REPORT::"Check (Stub/Stub/Check)");
    end;

    [Test]
    [HandlerFunctions('DocumentNoCheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVoidGenJnlLineFilterCheckStubError()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnPreDataItem Trigger of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnPreDataItemVoidGenJnlLineWithDocumentNo(REPORT::"Check (Stub/Check/Stub)");
    end;

    [Test]
    [HandlerFunctions('DocumentNoThreeChecksRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVoidGenJnlLineFilter3ChecksError()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnPreDataItem Trigger of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnPreDataItemVoidGenJnlLineWithDocumentNo(REPORT::"Three Checks per Page");
    end;

    local procedure OnPreDataItemVoidGenJnlLineWithDocumentNo(ReportID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
    begin
        // Create Bank Account and General Journal line.
        CreateBankAccount(BankAccount, LibraryRandom.RandIntInRange(0, 3), LibraryRandom.RandIntInRange(0, 2));  // Check Date Format - option Range 0 to 3 and Bank Communication - option Range 0 to 2.
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::"Bank Account", BankAccount."No.", BankAccount."No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Document No.");  // Enqueue Document number for handler - DocumentNoStubCheckRequestPageHandler or DocumentNoCheckStubRequestPageHandler or DocumentNoThreeChecksRequestPageHandler.

        // Exercise.
        asserterror REPORT.Run(ReportID);  // Invoke RequestPageHandler.

        // Verify: Verify Error Code, Actual error - Filters on Line No. and Document No. are not allowed.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('ReprintStubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVoidGenJnlLineReprintStubCheck()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordVoidGenJnlLineReprint(REPORT::"Check (Stub/Stub/Check)");
    end;

    [Test]
    [HandlerFunctions('ReprintCheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVoidGenJnlLineReprintCheckStub()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordVoidGenJnlLineReprint(REPORT::"Check (Stub/Check/Stub)");
    end;

    [Test]
    [HandlerFunctions('ReprintThreeChecksRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVoidGenJnlLineReprint3Checks()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordVoidGenJnlLineReprint(REPORT::"Three Checks per Page");
    end;

    local procedure OnAfterGetRecordVoidGenJnlLineReprint(ReportID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        // Create Bank Account, General Journal line and Check Ledger Entry.
        CreateBankAccount(BankAccount, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));  // Check Date Format - option Range 1 to 3 and Bank Communication Range 0 to 1.
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type", BankAccount."No.", BankAccount."No.");
        UpdateGeneralJournalLine(GenJournalLine, '', true, '');  // Blank value for Applies to ID and Check Printed - TRUE, Blank value - Applies to Document number.
        CreateCheckLedgerEntry(CheckLedgerEntry, GenJournalLine."Bal. Account No.", GenJournalLine."Document No.");

        // Exercise.
        REPORT.Run(ReportID);  // Set Reprint Checks as True on handler - ReprintStubCheckRequestPageHandler or ReprintCheckStubRequestPageHandler or ReprintThreeChecksRequestPageHandler .

        // Verify: Verify Entry Status - option as Voided, Original Entry Status as Printed and Open as False in Check Ledger Entry.
        VerifyCheckLedgerEntry(CheckLedgerEntry."Entry No.", CheckLedgerEntry."Entry Status");
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 1401 - Check.
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesType(REPORT::Check, GenJournalLine."Account Type", '');  // Blank value for Applies to Document Number.
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubStubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesStubCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesType(REPORT::"Check (Stub/Stub/Check)", GenJournalLine."Account Type", '');  // Blank value for Applies to Document Number.
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubCheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesCheckStub()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesType(REPORT::"Check (Stub/Check/Stub)", GenJournalLine."Account Type", '');  // Blank value for Applies to Document Number.
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoThreeChecksRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLines3Checks()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10413 - Three Checks per Page.
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesType(REPORT::"Three Checks per Page", GenJournalLine."Account Type", '');  // Blank value for Applies to Document Number.
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesGLAccCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 1401 - Check.
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesType(
          REPORT::Check, GenJournalLine."Account Type"::"G/L Account", LibraryUTUtility.GetNewCode());  // Generate new code for Applies To Document Number.
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubStubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesGLAccStubCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesType(
          REPORT::"Check (Stub/Stub/Check)", GenJournalLine."Account Type"::"G/L Account", LibraryUTUtility.GetNewCode());  // Generate new code for Applies to Document Number.
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubCheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesGLAccCheckStub()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesType(
          REPORT::"Check (Stub/Check/Stub)", GenJournalLine."Account Type"::"G/L Account", LibraryUTUtility.GetNewCode());  // Generate new code for Applies to Document Number.
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoThreeChecksRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesGLAcc3Checks()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10413 - Three Checks per Page.
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesType(
          REPORT::"Three Checks per Page", GenJournalLine."Account Type"::"G/L Account", LibraryUTUtility.GetNewCode());  // Generate new code for Applies to Document Number.
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesBankAccCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 1401 - Check.
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesType(
          REPORT::Check, GenJournalLine."Account Type"::"Bank Account", LibraryUTUtility.GetNewCode());  // Generate new code for Applies to Document Number.
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubStubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesBankAccStubCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesType(
          REPORT::"Check (Stub/Stub/Check)", GenJournalLine."Account Type"::"Bank Account", LibraryUTUtility.GetNewCode());  // Generate new code for Applies to Document Number.
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubCheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesBankAccCheckStub()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesType(
          REPORT::"Check (Stub/Check/Stub)", GenJournalLine."Account Type"::"Bank Account", LibraryUTUtility.GetNewCode());  // Generate new code for Applies to Document Number.
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoThreeChecksRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesBankAcc3Checks()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10413 - Three Checks per Page.
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesType(
          REPORT::"Three Checks per Page", GenJournalLine."Account Type"::"Bank Account", LibraryUTUtility.GetNewCode());  // Generate new code for Applies to Document Number.
    end;

    local procedure OnAfterGetRecordGenJnlLineApplyMethodMoreLinesType(ReportID: Integer; AccountType: Enum "Gen. Journal Account Type"; AppliesToDocumentNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        // Create Bank Account and General Journal line.
        CreateBankAccount(BankAccount, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));  // Check Date Format - option Range 1 to 3 and Bank Communication Range 0 to 1.
        CreateGenJournalLine(GenJournalLine, AccountType, BankAccount."No.", BankAccount."No.");
        UpdateGeneralJournalLine(GenJournalLine, '', true, AppliesToDocumentNo);  // Blank value for Applies to ID and Check Printed - TRUE.
        CreateCheckLedgerEntry(CheckLedgerEntry, GenJournalLine."Bal. Account No.", GenJournalLine."Document No.");

        // Exercise: Execute code Apply Method option - More Lines One Entry on Report - Check or Check (Stub/Stub/Check) or Check (Stub/Check/Stub).
        REPORT.Run(ReportID);  // Invoke RequestPageHandler.

        // Verify: Verify Posting Description on Report - Check or Check (Stub/Stub/Check) or Check (Stub/Check/Stub).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PostingDescriptionCap, GenJournalLine.Description);
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineOneLineIDCustomerStubCheck()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodOneLineIDCustomer(REPORT::"Check (Stub/Stub/Check)");
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineOneLineIDCustomerCheckStub()
    begin
        // Purpose of the test is to VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodOneLineIDCustomer(REPORT::"Check (Stub/Check/Stub)");
    end;

    local procedure OnAfterGetRecordGenJnlLineApplyMethodOneLineIDCustomer(ReportID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
    begin
        // Create Customer, Bank Account, General Journal line with Account Type Customer and Customer Ledger Entry.
        CreateCustomer(Customer, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));  // Check Date Format - option Range 1 to 3 and Bank Communication Range 0 to 1.
        CreateBankAccount(BankAccount, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));  // Check Date Format- option Range 1 to 3 and Bank Communication Range 0 to 1.
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", BankAccount."No.");
        UpdateGeneralJournalLine(GenJournalLine, LibraryUTUtility.GetNewCode(), false, '');  // Check Printed - FALSE, Blank value - Applies to Document number.
        CreateCustomerLedgerEntry(GenJournalLine);  // Create Customer Ledger Entry with Applies to ID execute code ApplyMethod - OneLineID on Report.

        // Exercise.
        REPORT.Run(ReportID);  // Invoke RequestPageHandler.

        // Verify: Verify Check number caption and Document Number on Report - Check (Stub/Stub/Check) or Check (Stub/Check/Stub).
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        VerifyCheckCaptionAndNumber(GenJournalLine."Document No.", CheckTextCap);
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineOneLineIDVendorStubCheck()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodOneLineIDVendor(REPORT::"Check (Stub/Stub/Check)");
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineOneLineIDVendorCheckStub()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodOneLineIDVendor(REPORT::"Check (Stub/Check/Stub)");
    end;

    local procedure OnAfterGetRecordGenJnlLineApplyMethodOneLineIDVendor(ReportID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
    begin
        // Create Vendor, Bank Account, General Journal line with Account Type Vendor and Vendor Ledger Entry.
        CreateVendor(Vendor, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));  // Check Date Format - option Range 1 to 3 and Bank Communication Range 0 to 1.
        CreateBankAccount(BankAccount, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));  // Check Date Format- option Range 1 to 3 and Bank Communication Range 0 to 1.
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", BankAccount."No.");
        UpdateGeneralJournalLine(GenJournalLine, LibraryUTUtility.GetNewCode(), false, '');  // Check Printed - FALSE, Blank value - Applies to Document number.
        CreateVendorLedgerEntry(GenJournalLine);  // Create Vendor Ledger Entry with Applies to ID execute code ApplyMethod - OneLineID on Report.

        // Exercise.
        REPORT.Run(ReportID);  // Invoke RequestPageHandler.

        // Verify: Verify Check caption and Check number on Report - Check (Stub/Stub/Check) or Check (Stub/Check/Stub).
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        VerifyCheckCaptionAndNumber(GenJournalLine."Document No.", CheckTextCap);
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesCustomerCheck()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 1401 - Check.
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesCustomer(REPORT::Check);
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubStubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesCustomerStubCheck()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesCustomer(REPORT::"Check (Stub/Stub/Check)");
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubCheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesCustomerCheckStub()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesCustomer(REPORT::"Check (Stub/Check/Stub)");
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoThreeChecksRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesCustomer3Checks()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10413 - Three Checks per Page.
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesCustomer(REPORT::"Three Checks per Page");
    end;

    local procedure OnAfterGetRecordGenJnlLineApplyMethodMoreLinesCustomer(ReportID: Integer)
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
    begin
        // Create Customer, Bank Account, General Journal line with Account Type Customer and Customer Ledger Entry.
        CreateCustomer(Customer, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));  // Check Date Format - option Range 1 to 3 and Bank Communication Range 0 to 1.
        CreateBankAccount(BankAccount, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));  // Check Date Format- option Range 1 to 3 and Bank Communication Range 0 to 1.
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", BankAccount."No.");
        UpdateGeneralJournalLine(GenJournalLine, '', false, LibraryUTUtility.GetNewCode());  // Blank value - Applies to ID and Check Printed - FALSE.
        CreateCustomerLedgerEntry(GenJournalLine);

        // Exercise.
        REPORT.Run(ReportID);  // Invoke RequestPageHandler.

        // Verify: Verify Posting Description on Report - Check or Check (Stub/Stub/Check) or Check (Stub/Check/Stub).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PostingDescriptionCap, GenJournalLine.Description);
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesVendorCheck()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 1401 - Check.
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesVendor(REPORT::Check);
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubStubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesVendorStubCheck()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesVendor(REPORT::"Check (Stub/Stub/Check)");
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubCheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesVendorCheckStub()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesVendor(REPORT::"Check (Stub/Check/Stub)");
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoThreeChecksRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineMoreLinesVendor3Checks()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10413 - Three Checks per Page.
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodMoreLinesVendor(REPORT::"Three Checks per Page");
    end;

    [HandlerFunctions('OneCheckPerVendorPerDocNoCheckRequestPageHandler')]
    local procedure OnAfterGetRecordGenJnlLineApplyMethodMoreLinesVendor(ReportID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
    begin
        // Create Vendor, Bank Account, General Journal line with Account Type Vendor and Vendor Ledger Entry.
        CreateVendor(Vendor, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));  // Check Date Format - option Range 1 to 3 and Bank Communication Range 0 to 1.
        CreateBankAccount(BankAccount, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));  // Check Date Format- option Range 1 to 3 and Bank Communication Range 0 to 1.
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", BankAccount."No.");
        UpdateGeneralJournalLine(GenJournalLine, '', false, LibraryUTUtility.GetNewCode());  // Check Printed - FALSE, Blank value - Applies to ID.
        CreateVendorLedgerEntry(GenJournalLine);

        // Exercise.
        REPORT.Run(ReportID);  // Invoke RequestPageHandler.

        // Verify: Verify Posting Description on Report - Check or Check (Stub/Stub/Check) or Check (Stub/Check/Stub).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PostingDescriptionCap, GenJournalLine.Description);
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetCheckPrintParamsUSCountryRegionCodeCheck()
    var
        CheckStyle: Option ,US,CA;
    begin
        // Purpose of the test is to validate  SetCheckPrintParams function of Report 1401 - Check.
        // Setup.
        Initialize();
        SetCheckPrintParamsCountryRegionCodeType(REPORT::Check, 'US', CheckStyle::US);  // Company Information Region - US and Check Style - US in Report - Check.
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetCheckPrintParamsCanadaCountryRegionCodeCheck()
    var
        CheckStyle: Option ,US,CA;
    begin
        // Purpose of the test is to validate  SetCheckPrintParams function of Report 1401 - Check.
        // Setup.
        Initialize();
        SetCheckPrintParamsCountryRegionCodeType(REPORT::Check, 'CA', CheckStyle::CA);  // Company Information Region - Canada and Check Style - CA in Report - Check.
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetCheckPrintParamsMexicoCountryRegionCodeCheck()
    var
        CheckStyle: Option ,US,CA;
    begin
        // Purpose of the test is to validate  SetCheckPrintParams function of Report 1401 - Check.
        // Setup.
        Initialize();
        SetCheckPrintParamsCountryRegionCodeType(REPORT::Check, 'MX', CheckStyle::US);  // Company Information Region - Mexico and Check Style - US in Report - Check.
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetCheckPrintParamsUSCountryRegionCodeStubCheck()
    var
        CheckStyle: Option ,US,CA;
    begin
        // Purpose of the test is to validate  SetCheckPrintParams function of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        SetCheckPrintParamsCountryRegionCodeType(REPORT::"Check (Stub/Stub/Check)", 'US', CheckStyle::US); // Company Information Region - US and Check Style - US in Report - Check (Stub/Stub/Check).
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetCheckPrintParamsCanadaCountryRegionCodeStubCheck()
    begin
        // Purpose of the test is to validate  SetCheckPrintParams function of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        SetCheckPrintParamsCountryRegionCodeType(REPORT::"Check (Stub/Stub/Check)", 'CA', 0);  // Company Information Region - Canada and Check Style - 0 in Report - Check (Stub/Stub/Check).
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetCheckPrintParamsMexicoCountryRegionCodeStubCheck()
    var
        CheckStyle: Option ,US,CA;
    begin
        // Purpose of the test is to validate  SetCheckPrintParams function of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        SetCheckPrintParamsCountryRegionCodeType(REPORT::"Check (Stub/Stub/Check)", 'MX', CheckStyle::US);  // Company Information Region - Mexico and Check Style - US in Report - Check (Stub/Stub/Check).
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetCheckPrintParamsUSCountryRegionCodeCheckStub()
    var
        CheckStyle: Option ,US,CA;
    begin
        // Purpose of the test is to validate  SetCheckPrintParams function of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        SetCheckPrintParamsCountryRegionCodeType(REPORT::"Check (Stub/Check/Stub)", 'US', CheckStyle::US);  // Company Information Region - US and Check Style - US in Report - Check (Stub/Check/Stub).
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetCheckPrintParamsCanadaCountryRegionCodeCheckStub()
    begin
        // Purpose of the test is to validate  SetCheckPrintParams function of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        SetCheckPrintParamsCountryRegionCodeType(REPORT::"Check (Stub/Check/Stub)", 'CA', 0);  // Company Information Region - Canada and Check Style - 0 in Report - Check (Stub/Check/Stub).
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetCheckPrintParamsMexicoCountryRegionCodeCheckStub()
    var
        CheckStyle: Option ,US,CA;
    begin
        // Purpose of the test is to validate  SetCheckPrintParams function of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        SetCheckPrintParamsCountryRegionCodeType(REPORT::"Check (Stub/Check/Stub)", 'MX', CheckStyle::US);  // Company Information Region - Mexico and Check Style - US in Report - Check (Stub/Check/Stub).
    end;

    [Test]
    [HandlerFunctions('ThreeChecksRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetCheckPrintParamsUSCountryRegionCode3Checks()
    var
        CheckStyle: Option ,US,CA;
    begin
        // Purpose of the test is to validate  SetCheckPrintParams function of Report 10413 - Three Checks per Page.
        // Setup.
        Initialize();
        SetCheckPrintParamsCountryRegionCodeType(REPORT::"Three Checks per Page", 'US', CheckStyle::US);  // Company Information Region - US and Check Style - US in Report - Check (Stub/Check/Stub).
    end;

    [Test]
    [HandlerFunctions('ThreeChecksRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetCheckPrintParamsMexicoCountryRegionCode3Checks()
    var
        CheckStyle: Option ,US,CA;
    begin
        // Purpose of the test is to validate  SetCheckPrintParams function of Report 10413 - Three Checks per Page.
        // Setup.
        Initialize();
        SetCheckPrintParamsCountryRegionCodeType(REPORT::"Three Checks per Page", 'MX', CheckStyle::US);  // Company Information Region - Mexico and Check Style - US in Report - Check (Stub/Check/Stub).
    end;

    local procedure SetCheckPrintParamsCountryRegionCodeType(ReportID: Integer; CountryRegionCode: Code[10]; StyleIndex: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
    begin
        // Create Customer, Bank Account with Country Region Code, Create General Journal Line.
        CreateCustomer(Customer, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));  // Check Date Format - option Range 1 to 3 and Bank Communication Range 0 to 1.
        CreateBankAccount(BankAccount, Customer."Check Date Format", Customer."Bank Communication");
        BankAccount."Country/Region Code" := CountryRegionCode;
        BankAccount.Modify();
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", BankAccount."No.");

        // Exercise.
        REPORT.Run(ReportID);  // Invoke RequestPageHandler.

        // Verify: Verify Check Style Index on Report - Check or Check (Stub/Stub/Check) or Check (Stub/Check/Stub).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CheckStyleIndex', StyleIndex);
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineOneEntryCustomerStubCheck()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodOneEntryCustomer(REPORT::"Check (Stub/Stub/Check)");
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineOneEntryCustomerCheckStub()
    begin
        // Purpose of the test is to VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodOneEntryCustomer(REPORT::"Check (Stub/Check/Stub)");
    end;

    local procedure OnAfterGetRecordGenJnlLineApplyMethodOneEntryCustomer(ReportID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
    begin
        // Create Customer, Bank Account, General Journal line with Account Type Customer and Customer Ledger Entry.
        CreateCustomer(Customer, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));  // Check Date Format - option Range 1 to 3 and Bank Communication Range 0 to 1.
        CreateBankAccount(BankAccount, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));  // Check Date Format- option Range 1 to 3 and Bank Communication Range 0 to 1.
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", BankAccount."No.");
        UpdateGeneralJournalLine(GenJournalLine, '', false, LibraryUTUtility.GetNewCode());  // Check Printed - FALSE, Blank value - Applies to ID.
        CreateCustomerLedgerEntry(GenJournalLine);

        // Exercise.
        REPORT.Run(ReportID);  // Invoke RequestPageHandler.

        // Verify: Verify Check number caption and Document Number on Report - Check (Stub/Stub/Check) or Check (Stub/Check/Stub).
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        VerifyCheckCaptionAndNumber(GenJournalLine."Document No.", CheckTextCap);
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineOneEntryVendorStubCheck()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10401 - Check (Stub/Stub/Check).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodOneEntryVendor(REPORT::"Check (Stub/Stub/Check)");
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineOneEntryVendorCheckStub()
    begin
        // Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10411 - Check (Stub/Check/Stub).
        // Setup.
        Initialize();
        OnAfterGetRecordGenJnlLineApplyMethodOneEntryVendor(REPORT::"Check (Stub/Check/Stub)");
    end;

    local procedure OnAfterGetRecordGenJnlLineApplyMethodOneEntryVendor(ReportID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
    begin
        // Create Vendor, Bank Account, General Journal line with Account Type Vendor and Vendor Ledger Entry.
        CreateVendor(Vendor, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));  // Check Date Format - option Range 1 to 3 and Bank Communication Range 0 to 1.
        CreateBankAccount(BankAccount, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));  // Check Date Format- option Range 1 to 3 and Bank Communication Range 0 to 1.
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", BankAccount."No.");
        UpdateGeneralJournalLine(GenJournalLine, '', false, LibraryUTUtility.GetNewCode());  // Check Printed - FALSE, Blank value - Applies to ID.
        CreateVendorLedgerEntry(GenJournalLine);

        // Exercise.
        REPORT.Run(ReportID);  // Invoke RequestPageHandler.

        // Verify: Verify Check caption and Check number on Report - Check (Stub/Stub/Check) or Check (Stub/Check/Stub).
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        VerifyCheckCaptionAndNumber(GenJournalLine."Document No.", CheckTextCap);
    end;

    [Test]
    [HandlerFunctions('CheckTranslationManagementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestLanguageTypeENUCheckTranslationManagement()
    var
        TestLanguage: Option ENU,ENC,FRC,ESM;
    begin
        // Purpose of the test is to validate OnPreReport of Report 10400 - Check Translation Management.
        // Setup.
        Initialize();
        TestLanguageTypeCheckTranslationManagement(TestLanguage::ENU, 'ENU');  // Text - ENU and Test Language option - ENU used on Report - Check Translation Management.
    end;

    [Test]
    [HandlerFunctions('CheckTranslationManagementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestLanguageTypeENCCheckTranslationManagement()
    var
        TestLanguage: Option ENU,ENC,FRC,ESM;
    begin
        // Purpose of the test is to validate OnPreReport of Report 10400 - Check Translation Management.
        // Setup.
        Initialize();
        TestLanguageTypeCheckTranslationManagement(TestLanguage::ENC, 'ENC');  // Text - ENC and Test Language option - ENC used on Report - Check Translation Management.
    end;

    [Test]
    [HandlerFunctions('CheckTranslationManagementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestLanguageTypeFRCCheckTranslationManagement()
    var
        TestLanguage: Option ENU,ENC,FRC,ESM;
    begin
        // Purpose of the test is to validate OnPreReport of Report 10400 - Check Translation Management.
        // Setup.
        Initialize();
        TestLanguageTypeCheckTranslationManagement(TestLanguage::FRC, 'FRC');  // Text - FRC and Test Language option - FRC used on Report - Check Translation Management.
    end;

    [Test]
    [HandlerFunctions('CheckTranslationManagementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestLanguageTypeESMCheckTranslationManagement()
    var
        TestLanguage: Option ENU,ENC,FRC,ESM;
    begin
        // Purpose of the test is to validate OnPreReport of Report 10400 - Check Translation Management.
        // Setup.
        Initialize();
        TestLanguageTypeCheckTranslationManagement(TestLanguage::ESM, 'ESM');  // Text - ESM and Test Language option - ESM used on Report - Check Translation Management.
    end;

    local procedure TestLanguageTypeCheckTranslationManagement(TestLanguage: Option; TestLanguageValue: Text)
    begin
        LibraryVariableStorage.Enqueue(TestLanguage);  // Enqueue value for CheckTranslationManagementRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Check Translation Management");  // Invoke CheckTranslationManagementRequestPageHandler.

        // Verify: Verify Test Language on Report - Check Translation Management.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TestLanguage', TestLanguageValue);
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountLineForCreditMemoReport10411()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Discount: Decimal;
    begin
        // [FEATURE] [Check printing] [Payment Journal]
        // [SCENARIO 375817] Payment Discount Line should be considered for Credit Memo by Check report 10411

        // [GIVEN] Credit Memo Journal Line
        // [GIVEN] Payment Journal Line
        CreateCreditMemoJournalLineWithPayment(GenJournalLine);

        // [GIVEN] Vendor Ledger Entry with "Remaining Pmt. Disc. Possible" = "X"
        Discount := LibraryRandom.RandDec(10, 2);
        UpdateVendLedgEntryDocTypeAndDisc(CreateVendorLedgerEntry(GenJournalLine), Discount);

        // [WHEN] Run Check report 10411
        Commit();
        REPORT.Run(REPORT::"Check (Stub/Check/Stub)");

        // [THEN] Payment Discount Line is printed with Discount = "-X"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('LineDiscount', -Discount);
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountLineForCreditMemoReport10401()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Discount: Decimal;
    begin
        // [FEATURE] [Check printing] [Payment Journal]
        // [SCENARIO 375817] Payment Discount Line should be considered for Credit Memo by Check report 10401

        // [GIVEN] Credit Memo Journal Line
        // [GIVEN] Payment Journal Line
        CreateCreditMemoJournalLineWithPayment(GenJournalLine);

        // [GIVEN] Vendor Ledger Entry with "Remaining Pmt. Disc. Possible" = "X"
        Discount := LibraryRandom.RandDec(10, 2);
        UpdateVendLedgEntryDocTypeAndDisc(CreateVendorLedgerEntry(GenJournalLine), Discount);

        // [WHEN] Run Check report 10401
        Commit();
        REPORT.Run(REPORT::"Check (Stub/Stub/Check)");

        // [THEN] Payment Discount Line is printed with Discount = "-X"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('LineDiscount', -Discount);
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubStubCheckRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RestrictedRecordIsNotCreatedForCheckPrintedJournalLine_StubStubCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ReportSelections: Record "Report Selections";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [FEATURE] [Payment Journal] [Workflow] [Approval]
        // [SCENARIO 254460] Payment Journal Line created as result of Stub/Stub/Check print is not restricted record when General Journal Batch Approval Workflow is enabled.
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"B.Check", REPORT::"Check (Stub/Stub/Check)");

        // [GIVEN] General Journal Batch Approval Workflow is enabled for direct approvers.
        // [GIVEN] Approval User Setup with direct approvers.
        SetupGenJnlBatchApprovalWorkflowWithUsers();

        // [GIVEN] Payment Journal Batch "Batch" with a Payment Line "PL" to Vendor.
        CreatePmtJnlBatchWithOnePaymentLineForAccTypeVendor(
          GenJournalBatch, GenJournalLine, GenJournalLine."Bank Payment Type"::"Computer Check");

        // [GIVEN] "Batch" is send for approval and approved.
        BindSubscription(LibraryJobQueue);
        SendAndApprovePaymentJournalBatch(GenJournalLine, GenJournalBatch.RecordId);

        Commit();

        // [WHEN] A Check is printed for "PL" with "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(true);
        PrintCheckForPaymentJournalLine(GenJournalLine, GenJournalLine."Bal. Account Type"::"G/L Account");

        // [THEN] A new Payment Line "PL-check" is created for Check.
        VerifyPaymentJournalLineCreatedforCheck(GenJournalLine, GenJournalBatch."Bal. Account No.");

        // [THEN] No restricted record is created for "PL-check"
        VerifyRestrictionRecordNotExisting(GenJournalLine.RecordId);

        // [THEN] "Batch" is posted.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        VerifyVendorLedgerEntryExistsWithExternalDocNo(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubCheckStubRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RestrictedRecordIsNotCreatedForCheckPrintedJournalLine_StubCheckStub()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ReportSelections: Record "Report Selections";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [FEATURE] [Payment Journal] [Workflow] [Approval]
        // [SCENARIO 254460] Payment Journal Line created as result of Stub/Check/Stub Print is not restricted record when General Journal Batch Approval Workflow is enabled.
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"B.Check", REPORT::"Check (Stub/Check/Stub)");

        // [GIVEN] General Journal Batch Approval Workflow is enabled for direct approvers.
        // [GIVEN] Approval User Setup with direct approvers.
        SetupGenJnlBatchApprovalWorkflowWithUsers();

        // [GIVEN] Payment Journal Batch "Batch" with a Payment Line "PL" to Vendor.
        CreatePmtJnlBatchWithOnePaymentLineForAccTypeVendor(
          GenJournalBatch, GenJournalLine, GenJournalLine."Bank Payment Type"::"Computer Check");

        // [GIVEN] "Batch" is send for approval and approved.
        BindSubscription(LibraryJobQueue);
        SendAndApprovePaymentJournalBatch(GenJournalLine, GenJournalBatch.RecordId);

        Commit();

        // [WHEN] A Check is printed for "PL" with "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(true);
        PrintCheckForPaymentJournalLine(GenJournalLine, GenJournalLine."Bal. Account Type"::"G/L Account");

        // [THEN] A new Payment Line "PL-check" is created for Check.
        VerifyPaymentJournalLineCreatedforCheck(GenJournalLine, GenJournalBatch."Bal. Account No.");

        // [THEN] No restricted record is created for "PL-check"
        VerifyRestrictionRecordNotExisting(GenJournalLine.RecordId);

        // [THEN] "Batch" is posted.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        VerifyVendorLedgerEntryExistsWithExternalDocNo(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoCheckStubStubRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RestrictedRecordIsNotCreatedForCheckPrintedJournalLine_CheckStubStub()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ReportSelections: Record "Report Selections";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [FEATURE] [Payment Journal] [Workflow] [Approval]
        // [SCENARIO 254460] Payment Journal Line created as result of Check/Stub/Stub Print is not restricted record when General Journal Batch Approval Workflow is enabled.
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"B.Check", REPORT::"Check (Check/Stub/Stub)");

        // [GIVEN] General Journal Batch Approval Workflow is enabled for direct approvers.
        // [GIVEN] Approval User Setup with direct approvers.
        SetupGenJnlBatchApprovalWorkflowWithUsers();

        // [GIVEN] Payment Journal Batch "Batch" with a Payment Line "PL" to Vendor.
        CreatePmtJnlBatchWithOnePaymentLineForAccTypeVendor(
          GenJournalBatch, GenJournalLine, GenJournalLine."Bank Payment Type"::"Computer Check");

        // [GIVEN] "Batch" is send for approval and approved.
        BindSubscription(LibraryJobQueue);
        SendAndApprovePaymentJournalBatch(GenJournalLine, GenJournalBatch.RecordId);

        Commit();

        // [WHEN] A Check is printed for "PL" with "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(true);
        PrintCheckForPaymentJournalLine(GenJournalLine, GenJournalLine."Bal. Account Type"::"G/L Account");

        // [THEN] A new Payment Line "PL-check" is created for Check.
        VerifyPaymentJournalLineCreatedforCheck(GenJournalLine, GenJournalBatch."Bal. Account No.");

        // [THEN] No restricted record is created for "PL-check"
        VerifyRestrictionRecordNotExisting(GenJournalLine.RecordId);

        // [THEN] "Batch" is posted.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        VerifyVendorLedgerEntryExistsWithExternalDocNo(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubStubCheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PmtJnlBatchPostedWithPrintCheck_StubStubCheck()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [Payment Journal] [Workflow] [Approval]
        // [SCENARIO 254460] Payment Journal Batch Line created with Stub/Stub/Check Printed posted while no Approval Workflows enabled.
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"B.Check", REPORT::"Check (Stub/Stub/Check)");

        // [GIVEN] Payment Journal Batch "Batch" with a Payment Line "PL" to Vendor.
        CreatePmtJnlBatchWithOnePaymentLineForAccTypeVendor(
          GenJournalBatch, GenJournalLine, GenJournalLine."Bank Payment Type"::"Computer Check");

        Commit();

        // [WHEN] A Check is printed for "PL" without "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(false);
        PrintCheckForPaymentJournalLine(GenJournalLine, GenJournalLine."Bal. Account Type"::"Bank Account");

        // [THEN] "Check Printed" is set for "PL".
        GenJournalLine.Find();
        GenJournalLine.TestField("Check Printed", true);

        // [THEN] "Batch" is posted.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        VerifyVendorLedgerEntryExists(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubCheckStubRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PmtJnlBatchPostedWithPrintCheck_StubCheckStub()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [Payment Journal] [Workflow] [Approval]
        // [SCENARIO 254460] Payment Journal Batch Line created with Stub/Check/Stub Printed posted while no Approval Workflows enabled.
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"B.Check", REPORT::"Check (Stub/Check/Stub)");

        // [GIVEN] Payment Journal Batch "Batch" with a Payment Line "PL" to Vendor.
        CreatePmtJnlBatchWithOnePaymentLineForAccTypeVendor(
          GenJournalBatch, GenJournalLine, GenJournalLine."Bank Payment Type"::"Computer Check");

        Commit();

        // [WHEN] A Check is printed for "PL" without "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(false);
        PrintCheckForPaymentJournalLine(GenJournalLine, GenJournalLine."Bal. Account Type"::"Bank Account");

        // [THEN] "Check Printed" is set for "PL".
        GenJournalLine.Find();
        GenJournalLine.TestField("Check Printed", true);

        // [THEN] "Batch" is posted.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        VerifyVendorLedgerEntryExists(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoCheckStubStubRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PmtJnlBatchPostedWithPrintCheck_CheckStubStub()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [Payment Journal] [Workflow] [Approval]
        // [SCENARIO 254460] Payment Journal Batch Line created with Check/Stub/Stub Printed posted while no Approval Workflows enabled.
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"B.Check", REPORT::"Check (Check/Stub/Stub)");

        // [GIVEN] Payment Journal Batch "Batch" with a Payment Line "PL" to Vendor.
        CreatePmtJnlBatchWithOnePaymentLineForAccTypeVendor(
          GenJournalBatch, GenJournalLine, GenJournalLine."Bank Payment Type"::"Computer Check");

        Commit();

        // [WHEN] A Check is printed for "PL" without "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(false);
        PrintCheckForPaymentJournalLine(GenJournalLine, GenJournalLine."Bal. Account Type"::"Bank Account");

        // [THEN] "Check Printed" is set for "PL".
        GenJournalLine.Find();
        GenJournalLine.TestField("Check Printed", true);

        // [THEN] "Batch" is posted.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        VerifyVendorLedgerEntryExists(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubStubCheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PmtJnlBatchPostedWithPrintCheckAndOneCheckPerVendorOption_StubStubCheck()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [Payment Journal] [Workflow] [Approval]
        // [SCENARIO 254460] Payment Journal Batch Line created with Stub/Stub/Check Printed with "One Check Per Vendor" option posted while no Approval Workflows enabled.
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"B.Check", REPORT::"Check (Stub/Stub/Check)");

        // [GIVEN] Payment Journal Batch "Batch" with a Payment Line "PL" to Vendor.
        CreatePmtJnlBatchWithOnePaymentLineForAccTypeVendor(
          GenJournalBatch, GenJournalLine, GenJournalLine."Bank Payment Type"::"Computer Check");

        Commit();

        // [WHEN] A Check is printed for "PL" with "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(true);
        PrintCheckForPaymentJournalLine(GenJournalLine, GenJournalLine."Bal. Account Type"::"G/L Account");

        // [THEN] A new Payment Line "PL-check" is created for Check.
        VerifyPaymentJournalLineCreatedforCheck(GenJournalLine, GenJournalBatch."Bal. Account No.");

        // [THEN] "Batch" is posted.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        VerifyVendorLedgerEntryExistsWithExternalDocNo(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubCheckStubRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PmtJnlBatchPostedWithPrintCheckAndOneCheckPerVendorOption_StubCheckStub()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [Payment Journal] [Workflow] [Approval]
        // [SCENARIO 254460] Payment Journal Batch Line created with Stub/Check/Stub Printed with "One Check Per Vendor" option posted while no Approval Workflows enabled.
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"B.Check", REPORT::"Check (Stub/Check/Stub)");

        // [GIVEN] Payment Journal Batch "Batch" with a Payment Line "PL" to Vendor.
        CreatePmtJnlBatchWithOnePaymentLineForAccTypeVendor(
          GenJournalBatch, GenJournalLine, GenJournalLine."Bank Payment Type"::"Computer Check");

        Commit();

        // [WHEN] A Check is printed for "PL" with "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(true);
        PrintCheckForPaymentJournalLine(GenJournalLine, GenJournalLine."Bal. Account Type"::"G/L Account");

        // [THEN] A new Payment Line "PL-check" is created for Check.
        VerifyPaymentJournalLineCreatedforCheck(GenJournalLine, GenJournalBatch."Bal. Account No.");

        // [THEN] "Batch" is posted.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        VerifyVendorLedgerEntryExistsWithExternalDocNo(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoCheckStubStubRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PmtJnlBatchPostedWithPrintCheckAndOneCheckPerVendorOption_CheckStubStub()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [Payment Journal] [Workflow] [Approval]
        // [SCENARIO 254460] Payment Journal Batch Line created with Check/Stub/Stub Printed with "One Check Per Vendor" option posted while no Approval Workflows enabled.
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"B.Check", REPORT::"Check (Check/Stub/Stub)");

        // [GIVEN] Payment Journal Batch "Batch" with a Payment Line "PL" to Vendor.
        CreatePmtJnlBatchWithOnePaymentLineForAccTypeVendor(
          GenJournalBatch, GenJournalLine, GenJournalLine."Bank Payment Type"::"Computer Check");

        Commit();

        // [WHEN] A Check is printed for "PL" with "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(true);
        PrintCheckForPaymentJournalLine(GenJournalLine, GenJournalLine."Bal. Account Type"::"G/L Account");

        // [THEN] A new Payment Line "PL-check" is created for Check.
        VerifyPaymentJournalLineCreatedforCheck(GenJournalLine, GenJournalBatch."Bal. Account No.");

        // [THEN] "Batch" is posted.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        VerifyVendorLedgerEntryExistsWithExternalDocNo(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlBatchMustBeApprovedToPrintCheck()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyRestrictedRecord: Record "Restricted Record";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [Payment Journal] [Workflow] [Approval]
        // [SCENARIO 254460] Payment Journal Batch must be approved before print the check.
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"B.Check", REPORT::"Check (Stub/Stub/Check)");

        // [GIVEN] General Journal Batch Approval Workflow is enabled for direct approvers.
        // [GIVEN] Approval User Setup with direct approvers.
        SetupGenJnlBatchApprovalWorkflowWithUsers();

        // [GIVEN] Payment Journal Batch "Batch" with a Payment Line "PL" to Vendor.
        // [GIVEN] "Batch" is not approved.
        CreatePmtJnlBatchWithOnePaymentLineForAccTypeVendor(
          GenJournalBatch, GenJournalLine, GenJournalLine."Bank Payment Type"::"Computer Check");

        Commit();

        // [WHEN] Check Print is called for "Batch" with "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(true);
        asserterror PrintCheckForPaymentJournalLine(GenJournalLine, GenJournalLine."Bal. Account Type"::"G/L Account");

        // [THEN] Check cannot be printed with error invoked: "You cannot use Gen. Journal Line: %1,%2,%3 for this action.\\The restriction was imposed because the journal batch requires approval."
        Assert.ExpectedError(Format(GenJournalLine.RecordId));

        // [THEN] Restricted Record for "PL" exists.
        DummyRestrictedRecord.SetRange("Record ID", GenJournalLine.RecordId);
        Assert.RecordIsNotEmpty(DummyRestrictedRecord);
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubStubCheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RestrictCheckPrintWhenNotAllGenJnlLinesWereApprovedWithOneCheckPerVendorOption_StubStubCheck()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [Payment Journal] [Workflow] [Approval]
        // [SCENARIO 254460] With General Journal Line Approval Workflow enabled, all Payment Journal Lines must be approved to print Stub/Stub/Check with "One Check Per Vendor" option from Payment Journal.
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"B.Check", REPORT::"Check (Stub/Stub/Check)");

        // [GIVEN] General Journal Line Approval Workflow is enabled for direct approvers.
        // [GIVEN] Approval User Setup with direct approvers.
        SetupGenJnlLineApprovalWorkflowWithUsers();

        // [GIVEN] Payment Journal Batch with two Payment Lines "PL1" and "PL2" to Vendor, both with Document No. = "DOC".
        CreatePmtJnlBatchWithTwoPaymentLinesForAccTypeVendor(GenJournalBatch, GenJournalLine);

        // [GIVEN] "PL1" is send for approval and approved.
        SendAndApprovePaymentJournalLine(GenJournalLine[1], GenJournalLine[1].RecordId);

        Commit();

        // [WHEN] Print Check for "PL1" with "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(true);
        asserterror PrintCheckForPaymentJournalLine(GenJournalLine[1], GenJournalLine[1]."Bal. Account Type"::"G/L Account");

        // [THEN] Check cannot be printed with error invoked: "You cannot use Gen. Journal Line: %1,%2,%3 for this action.\\The restriction was imposed because the line requires approval."
        Assert.ExpectedError(Format(GenJournalLine[2].RecordId));
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubCheckStubRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RestrictCheckPrintWhenNotAllGenJnlLinesWereApprovedWithOneCheckPerVendorOption_StubCheckStub()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [Payment Journal] [Workflow] [Approval]
        // [SCENARIO 254460] With General Journal Line Approval Workflow enabled, all Payment Journal Lines must be approved to print Stub/Check/Stub with "One Check Per Vendor" option from Payment Journal.
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"B.Check", REPORT::"Check (Stub/Check/Stub)");

        // [GIVEN] General Journal Line Approval Workflow is enabled for direct approvers.
        // [GIVEN] Approval User Setup with direct approvers.
        SetupGenJnlLineApprovalWorkflowWithUsers();

        // [GIVEN] Payment Journal Batch with two Payment Lines "PL1" and "PL2" to Vendor, both with Document No. = "DOC".
        CreatePmtJnlBatchWithTwoPaymentLinesForAccTypeVendor(GenJournalBatch, GenJournalLine);

        // [GIVEN] "PL1" is send for approval and approved.
        SendAndApprovePaymentJournalLine(GenJournalLine[1], GenJournalLine[1].RecordId);

        Commit();

        // [WHEN] Print Check for "PL1" with "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(true);
        asserterror PrintCheckForPaymentJournalLine(GenJournalLine[1], GenJournalLine[1]."Bal. Account Type"::"G/L Account");

        // [THEN] Check cannot be printed with error invoked: "You cannot use Gen. Journal Line: %1,%2,%3 for this action.\\The restriction was imposed because the line requires approval."
        Assert.ExpectedError(Format(GenJournalLine[2].RecordId));
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoCheckStubStubRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RestrictCheckPrintWhenNotAllGenJnlLinesWereApprovedWithOneCheckPerVendorOption_CheckStubStub()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [Payment Journal] [Workflow] [Approval]
        // [SCENARIO 254460] With General Journal Line Approval Workflow enabled, all Payment Journal Lines must be approved to print Check/Stub/Stub with "One Check Per Vendor" option from Payment Journal.
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"B.Check", REPORT::"Check (Check/Stub/Stub)");

        // [GIVEN] General Journal Line Approval Workflow is enabled for direct approvers.
        // [GIVEN] Approval User Setup with direct approvers.
        SetupGenJnlLineApprovalWorkflowWithUsers();

        // [GIVEN] Payment Journal Batch with two Payment Lines "PL1" and "PL2" to Vendor, both with Document No. = "DOC".
        CreatePmtJnlBatchWithTwoPaymentLinesForAccTypeVendor(GenJournalBatch, GenJournalLine);

        // [GIVEN] "PL1" is send for approval and approved.
        SendAndApprovePaymentJournalLine(GenJournalLine[1], GenJournalLine[1].RecordId);

        Commit();

        // [WHEN] Print Check for "PL1" with "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(true);
        asserterror PrintCheckForPaymentJournalLine(GenJournalLine[1], GenJournalLine[1]."Bal. Account Type"::"G/L Account");

        // [THEN] Check cannot be printed with error invoked: "You cannot use Gen. Journal Line: %1,%2,%3 for this action.\\The restriction was imposed because the line requires approval."
        Assert.ExpectedError(Format(GenJournalLine[2].RecordId));
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubStubCheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RestrictCheckPrintWhenNotAllGenJnlLinesWereApprovedWithoutOneCheckPerVendorOption_StubStubCheck()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [Payment Journal] [Workflow] [Approval]
        // [SCENARIO 254460] With General Journal Line Approval Workflow enabled, all Payment Journal Lines must be approved to print Stub/Stub/Check without "One Check Per Vendor" option from Payment Journal.
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"B.Check", REPORT::"Check (Stub/Stub/Check)");

        // [GIVEN] General Journal Line Approval Workflow is enabled for direct approvers.
        // [GIVEN] Approval User Setup with direct approvers.
        SetupGenJnlLineApprovalWorkflowWithUsers();

        // [GIVEN] Payment Journal Batch with two Payment Lines "PL1" and "PL2" to Vendor, both with Document No. = "DOC".
        CreatePmtJnlBatchWithTwoPaymentLinesForAccTypeVendor(GenJournalBatch, GenJournalLine);

        // [GIVEN] "PL1" is send for approval and approved.
        SendAndApprovePaymentJournalLine(GenJournalLine[1], GenJournalLine[1].RecordId);

        Commit();

        // [WHEN] Print Check for "PL1" without "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(false);
        asserterror PrintCheckForPaymentJournalLine(GenJournalLine[1], GenJournalLine[1]."Bal. Account Type"::"G/L Account");

        // [THEN] Check cannot be printed with error invoked: "You cannot use Gen. Journal Line: %1,%2,%3 for this action.\\The restriction was imposed because the line requires approval."
        Assert.ExpectedError(Format(GenJournalLine[2].RecordId));
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoStubCheckStubRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RestrictCheckPrintWhenNotAllGenJnlLinesWereApprovedWithoutOneCheckPerVendorOption_StubCheckStub()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [Payment Journal] [Workflow] [Approval]
        // [SCENARIO 254460] With General Journal Line Approval Workflow enabled, all Payment Journal Lines must be approved to print Stub/Check/Stub without "One Check Per Vendor" option from Payment Journal.
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"B.Check", REPORT::"Check (Stub/Check/Stub)");

        // [GIVEN] General Journal Line Approval Workflow is enabled for direct approvers.
        // [GIVEN] Approval User Setup with direct approvers.
        SetupGenJnlLineApprovalWorkflowWithUsers();

        // [GIVEN] Payment Journal Batch with two Payment Lines "PL1" and "PL2" to Vendor, both with Document No. = "DOC".
        CreatePmtJnlBatchWithTwoPaymentLinesForAccTypeVendor(GenJournalBatch, GenJournalLine);

        // [GIVEN] "PL1" is send for approval and approved.
        SendAndApprovePaymentJournalLine(GenJournalLine[1], GenJournalLine[1].RecordId);

        Commit();

        // [WHEN] Print Check for "PL1" without "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(false);
        asserterror PrintCheckForPaymentJournalLine(GenJournalLine[1], GenJournalLine[1]."Bal. Account Type"::"G/L Account");

        // [THEN] Check cannot be printed with error invoked: "You cannot use Gen. Journal Line: %1,%2,%3 for this action.\\The restriction was imposed because the line requires approval."
        Assert.ExpectedError(Format(GenJournalLine[2].RecordId));
    end;

    [Test]
    [HandlerFunctions('OneCheckPerVendorPerDocNoCheckStubStubRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RestrictCheckPrintWhenNotAllGenJnlLinesWereApprovedWithoutOneCheckPerVendorOption_CheckStubStub()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [Payment Journal] [Workflow] [Approval]
        // [SCENARIO 254460] With General Journal Line Approval Workflow enabled, all Payment Journal Lines must be approved to print Check/Stub/Stub without "One Check Per Vendor" option from Payment Journal.
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"B.Check", REPORT::"Check (Check/Stub/Stub)");

        // [GIVEN] General Journal Line Approval Workflow is enabled for direct approvers.
        // [GIVEN] Approval User Setup with direct approvers.
        SetupGenJnlLineApprovalWorkflowWithUsers();

        // [GIVEN] Payment Journal Batch with two Payment Lines "PL1" and "PL2" to Vendor, both with Document No. = "DOC".
        CreatePmtJnlBatchWithTwoPaymentLinesForAccTypeVendor(GenJournalBatch, GenJournalLine);

        // [GIVEN] "PL1" is send for approval and approved.
        SendAndApprovePaymentJournalLine(GenJournalLine[1], GenJournalLine[1].RecordId);

        Commit();

        // [WHEN] Print Check for "PL1" without "One Check per Vendor per Document No." option.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");
        LibraryVariableStorage.Enqueue(false);
        asserterror PrintCheckForPaymentJournalLine(GenJournalLine[1], GenJournalLine[1]."Bal. Account Type"::"G/L Account");

        // [THEN] Check cannot be printed with error invoked: "You cannot use Gen. Journal Line: %1,%2,%3 for this action.\\The restriction was imposed because the line requires approval."
        Assert.ExpectedError(Format(GenJournalLine[2].RecordId));
    end;

    [Test]
    [HandlerFunctions('StubCheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineOneEntryEmployeeStubCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 304668] Purpose of the test is to validate VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10401 - Check (Stub/Stub/Check) for Employee.
        Initialize();

        // [GIVEN] Employee, Bank Account, General Journal line with Account Type Employee and Epmloyee Ledger Entry.
        CreateEmployeeBankAccGenJnlLineForEmployee(GenJournalLine);
        Commit();

        // [WHEN] Run report "Check (Stub/Stub/Check)"
        REPORT.Run(REPORT::"Check (Stub/Stub/Check)");

        // [THEN] Check number caption and Document Number on Report - Check (Stub/Stub/Check).
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        VerifyCheckCaptionAndNumber(GenJournalLine."Document No.", CheckTextCap);
    end;

    [Test]
    [HandlerFunctions('CheckStubRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJnlLineOneEntryEmployeeCheckStub()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 304668] Purpose of the test is to VoidGenJnlLine - OnAfterGetRecord Trigger of Report 10411 - Check (Stub/Check/Stub) for Employee.
        Initialize();

        // [GIVEN] Employee, Bank Account, General Journal line with Account Type Employee and Epmloyee Ledger Entry.
        CreateEmployeeBankAccGenJnlLineForEmployee(GenJournalLine);
        Commit();

        // [WHEN] Run report "Check (Stub/Check/Stub)"
        REPORT.Run(REPORT::"Check (Stub/Check/Stub)");

        // [THEN] Check number caption and Document Number on Report - Check (Stub/Check/Stub).
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        VerifyCheckCaptionAndNumber(GenJournalLine."Document No.", CheckTextCap);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatNoTextUSAmountInWordsKeepsAndCentsTogether()
    var
        CheckTranslationManagement: Report "Check Translation Management";
        Currency: Record Currency;
        NoText: array[2] of Text[80];
        Amount: Decimal;
        LanguageCode: Integer;
        Result: Boolean;
    begin
        // [FEATURE] [Check printing] [Amount in Words]
        // [SCENARIO 608968] Check print out in US Amount 177,777.76 should format correctly with "AND 76/100" staying together with Currency
        Initialize();

        // [GIVEN] Create currency "XXX" with description
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));
        Currency.Description := Currency.Code;
        Currency.Modify();

        // [GIVEN] Amount = 177,777.76 (the specific amount from the bug report)
        Amount := 177777.76;
        LanguageCode := 1033; // English (US)

        // [WHEN] Formatting the amount to text using FormatNoText method
        Result := CheckTranslationManagement.FormatNoText(NoText, Amount, LanguageCode, Currency.Code);

        // [THEN] The formatting operation should succeed for the given amount
        Assert.IsTrue(Result, StrSubstNo(FormatNoTextSuccessMsg, Amount));

        // [THEN] Verify "AND 76/100" appears only in NoText[2] with currency and not split in NoText[1]
        Assert.IsTrue((StrPos(NoText[1], 'AND 76/100') = 0) and (StrPos(NoText[2], 'AND 76/100 ' + Currency.Description) > 0), StrSubstNo(AndCentsInNoText2Msg, 'AND 76/100'));
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        UserSetup: Record "User Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        ApprovalEntry: Record "Approval Entry";
        ReportSelections: Record "Report Selections";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryVariableStorage.Clear();

        Workflow.ModifyAll(Enabled, false, true);
        UserSetup.DeleteAll();
        GenJournalTemplate.DeleteAll();
        ApprovalEntry.DeleteAll();
        LibraryWorkflow.DisableAllWorkflows();
        VendorLedgerEntry.DeleteAll();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"B.Check", REPORT::Check);
    end;

    local procedure Approve(var ApprovalEntry: Record "Approval Entry")
    var
        RequeststoApprove: TestPage "Requests to Approve";
    begin
        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        RequeststoApprove.Approve.Invoke();
    end;

    local procedure CreateGenJournalTemplateAndBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate.Insert();
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        GenJournalBatch.Insert();
    end;

    local procedure CreateCustomer(var Customer: Record Customer; CheckDateFormat: Option; BankCommunication: Option)
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer."Check Date Format" := CheckDateFormat;
        Customer."Bank Communication" := BankCommunication;
        Customer.Insert();
    end;

    local procedure CreateCustomerLedgerEntry(GenJournalLine: Record "Gen. Journal Line")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry."Entry No." := SelectCustomerLedgerEntryNo();
        CustLedgerEntry."Customer No." := GenJournalLine."Account No.";
        CustLedgerEntry."Document No." := GenJournalLine."Applies-to Doc. No.";
        CustLedgerEntry."Applies-to ID" := GenJournalLine."Applies-to ID";
        CustLedgerEntry.Description := GenJournalLine.Description;
        CustLedgerEntry."Amount to Apply" := -GenJournalLine.Amount;
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Positive := true;
        CustLedgerEntry.Insert();
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; CheckDateFormat: Option; BankCommunication: Option)
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor."Check Date Format" := CheckDateFormat;
        Vendor."Bank Communication" := BankCommunication;
        Vendor.Insert();
    end;

    local procedure CreateVendorLedgerEntry(GenJournalLine: Record "Gen. Journal Line"): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry."Entry No." := SelectVendorLedgerEntryNo();
        VendorLedgerEntry."Vendor No." := GenJournalLine."Account No.";
        VendorLedgerEntry."Document No." := GenJournalLine."Applies-to Doc. No.";
        VendorLedgerEntry."Applies-to ID" := GenJournalLine."Applies-to ID";
        VendorLedgerEntry.Description := GenJournalLine.Description;
        VendorLedgerEntry."Amount to Apply" := -GenJournalLine.Amount;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Positive := true;
        VendorLedgerEntry.Insert();
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure UpdateVendLedgEntryDocTypeAndDisc(EntryNo: Integer; Discount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Get(EntryNo);
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::"Credit Memo";
        VendorLedgerEntry."Pmt. Discount Date" := CalcDate('<+1M>', WorkDate());
        VendorLedgerEntry."Remaining Pmt. Disc. Possible" := Discount;
        VendorLedgerEntry.Modify(true);
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account"; CheckDateFormat: Option; BankCommunication: Option)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount."Last Check No." := LibraryUTUtility.GetNewCode();
        BankAccount."Country/Region Code" := 'CA';
        BankAccount."Check Date Format" := CheckDateFormat;
        BankAccount."Bank Communication" := BankCommunication;
        BankAccount.Insert();
        LibraryVariableStorage.Enqueue(BankAccount."No.");  // Enqueue value for Request Page handler - CheckRequestPageHandler or in other RequestPageHandler.
    end;

    local procedure CreateCreditMemoJournalLineWithPayment(var GenJournalLine: Record "Gen. Journal Line")
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));
        CreateBankAccount(BankAccount, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));
        CreateComputerCheckPmtLine(
            GenJournalLine, Vendor."No.", LibraryRandom.RandIntInRange(10, 100), GenJournalLine."Document Type"::"Credit Memo",
            GenJournalLine."Account Type"::Vendor, BankAccount."Currency Code");
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", BankAccount."No.");
        UpdateGeneralJournalLine(GenJournalLine, LibraryUTUtility.GetNewCode(), false, '');
    end;

    local procedure CreatePmtJnlBatchWithOnePaymentLineForAccTypeVendor(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line"; BankPaymentType: Enum "Bank Payment Type")
    begin
        CreatePaymentJournalBatchWithOneJournalLine(
          GenJournalBatch, GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo());
        GenJournalLine."Bank Payment Type" := BankPaymentType;
        GenJournalLine.Modify();
    end;

    local procedure CreatePaymentJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Last Check No." := Format(1);
        BankAccount.Modify();

        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate(),
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.");
        CreateJournalBatch(GenJournalBatch, LibraryPurchase.SelectPmtJnlTemplate(),
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.");

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, AccountType, AccountNo, LibraryRandom.RandDec(100, 2));

        // Enqueue value for Request Page handler
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
    end;

    local procedure CreatePmtJnlBatchWithTwoPaymentLinesForAccTypeVendor(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: array[2] of Record "Gen. Journal Line")
    begin
        CreatePaymentJournalBatchWithOneJournalLine(
          GenJournalBatch, GenJournalLine[1], GenJournalLine[1]."Document Type"::Payment,
          GenJournalLine[1]."Account Type"::Vendor, LibraryPurchase.CreateVendorNo());

        GenJournalLine[1]."Bank Payment Type" := GenJournalLine[1]."Bank Payment Type"::"Computer Check";
        GenJournalLine[1].Modify();

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine[2], GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine[2]."Document Type"::Payment, GenJournalLine[2]."Account Type"::Vendor,
          GenJournalLine[1]."Account No.", LibraryRandom.RandDec(100, 2));

        GenJournalLine[2]."Document No." := GenJournalLine[1]."Document No.";
        GenJournalLine[2]."Bank Payment Type" := GenJournalLine[2]."Bank Payment Type"::"Computer Check";
        GenJournalLine[2].Modify();
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplateAndBatch(GenJournalBatch);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine."Line No." := LibraryRandom.RandInt(10);
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine."Bal. Account No." := BalAccountNo;
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Computer Check";
        GenJournalLine.Amount := LibraryRandom.RandDecInRange(10, 100, 2);
        GenJournalLine.Description := LibraryUTUtility.GetNewCode();
        // Test MAX length = 35 (TFS ID: 305391)
        GenJournalLine."External Document No." := CopyStr(LibraryUtility.GenerateRandomXMLText(35), 1);
        GenJournalLine.Insert();

        // Enqueue value for Request Page handler - CheckRequestPageHandler or in other RequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
    end;

    local procedure CreateCheckLedgerEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountNo: Code[20]; CheckNo: Code[20])
    begin
        CheckLedgerEntry."Entry No." := SelectCheckLedgerEntryNo();
        CheckLedgerEntry."Bank Account No." := BankAccountNo;
        CheckLedgerEntry."Entry Status" := CheckLedgerEntry."Entry Status"::Printed;
        CheckLedgerEntry."Check No." := CheckNo;
        CheckLedgerEntry.Open := true;
        CheckLedgerEntry.Insert();
    end;

    local procedure CreateEmployeeBankAccGenJnlLineForEmployee(var GenJournalLine: Record "Gen. Journal Line")
    var
        BankAccount: Record "Bank Account";
    begin
        CreateBankAccount(BankAccount, LibraryRandom.RandIntInRange(1, 3), LibraryRandom.RandIntInRange(0, 1));  // Check Date Format- option Range 1 to 3 and Bank Communication Range 0 to 1.
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Employee, CreateEmployee(), BankAccount."No.");
        UpdateGeneralJournalLine(GenJournalLine, '', false, LibraryUTUtility.GetNewCode());  // Check Printed - FALSE, Blank value - Applies to ID.
        MockOpenPositiveEmployeeLedgerEntry(GenJournalLine);
    end;

    local procedure CreateEmployee(): Code[20]
    var
        Employee: Record Employee;
    begin
        Employee.Init();
        Employee."No." := LibraryUtility.GenerateGUID();
        Employee.Insert();
        exit(Employee."No.");
    end;

    local procedure MockOpenPositiveEmployeeLedgerEntry(GenJournalLine: Record "Gen. Journal Line")
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(EmployeeLedgerEntry, EmployeeLedgerEntry.FieldNo("Entry No."));
        EmployeeLedgerEntry."Employee No." := GenJournalLine."Account No.";
        EmployeeLedgerEntry."Document No." := GenJournalLine."Applies-to Doc. No.";
        EmployeeLedgerEntry."Applies-to ID" := GenJournalLine."Applies-to ID";
        EmployeeLedgerEntry.Description := GenJournalLine.Description;
        EmployeeLedgerEntry."Amount to Apply" := -GenJournalLine.Amount;
        EmployeeLedgerEntry.Open := true;
        EmployeeLedgerEntry.Positive := true;
        EmployeeLedgerEntry.Insert();
    end;

    local procedure SelectCheckLedgerEntryNo(): Integer
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        if CheckLedgerEntry.FindLast() then
            exit(CheckLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure SelectVendorLedgerEntryNo(): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if VendorLedgerEntry.FindLast() then
            exit(VendorLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure SelectCustomerLedgerEntryNo(): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry.FindLast() then
            exit(CustLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure FilterOnReportCheckRequestPage(var Check: TestRequestPage Check; ReprintChecks: Boolean; OneCheckPerVendorPerDocumentNo: Boolean)
    var
        BankAccount: Variant;
        JournalBatchName: Variant;
        JournalTemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccount);
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        Check.VoidGenJnlLine.SetFilter("Journal Template Name", JournalTemplateName);
        Check.VoidGenJnlLine.SetFilter("Journal Batch Name", JournalBatchName);
        Check.ReprintChecks.SetValue(ReprintChecks);
        Check.OneCheckPerVendorPerDocumentNo.SetValue(OneCheckPerVendorPerDocumentNo);
        Check.BankAccount.SetValue(BankAccount);
    end;

    local procedure FilterOnReportStubStubCheckRequestPage(var StubCheck: TestRequestPage "Check (Stub/Stub/Check)"; ReprintChecks: Boolean; OneCheckPerVendorPerDocumentNo: Boolean)
    var
        BankAccount: Variant;
        JournalBatchName: Variant;
        JournalTemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccount);
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        StubCheck.VoidGenJnlLine.SetFilter("Journal Template Name", JournalTemplateName);
        StubCheck.VoidGenJnlLine.SetFilter("Journal Batch Name", JournalBatchName);
        StubCheck.ReprintChecks.SetValue(ReprintChecks);
        StubCheck.OneCheckPerVendorPerDocumentNo.SetValue(OneCheckPerVendorPerDocumentNo);
        StubCheck.BankAccount.SetValue(BankAccount);
    end;

    local procedure FilterOnReportStubCheckStubRequestPage(var CheckStub: TestRequestPage "Check (Stub/Check/Stub)"; ReprintChecks: Boolean; OneCheckPerVendorPerDocumentNo: Boolean)
    var
        BankAccount: Variant;
        JournalBatchName: Variant;
        JournalTemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccount);
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        CheckStub.VoidGenJnlLine.SetFilter("Journal Template Name", JournalTemplateName);
        CheckStub.VoidGenJnlLine.SetFilter("Journal Batch Name", JournalBatchName);
        CheckStub.ReprintChecks.SetValue(ReprintChecks);
        CheckStub.OneCheckPerVendorPerDocumentNo.SetValue(OneCheckPerVendorPerDocumentNo);
        CheckStub.BankAccount.SetValue(BankAccount);
    end;

    local procedure FilterOnReportCheckStubStubRequestPage(var CheckStub: TestRequestPage "Check (Check/Stub/Stub)"; ReprintChecks: Boolean; OneCheckPerVendorPerDocumentNo: Boolean)
    var
        BankAccount: Variant;
        JournalBatchName: Variant;
        JournalTemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccount);
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        CheckStub.VoidGenJnlLine.SetFilter("Journal Template Name", JournalTemplateName);
        CheckStub.VoidGenJnlLine.SetFilter("Journal Batch Name", JournalBatchName);
        CheckStub.ReprintChecks.SetValue(ReprintChecks);
        CheckStub.OneCheckPerVendorPerDocumentNo.SetValue(OneCheckPerVendorPerDocumentNo);
        CheckStub.BankAccount.SetValue(BankAccount);
    end;

    local procedure UpdateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AppliesToID: Code[50]; CheckPrinted: Boolean; AppliesToDocNo: Code[20])
    begin
        GenJournalLine."Applies-to ID" := AppliesToID;
        GenJournalLine."Check Printed" := CheckPrinted;
        GenJournalLine."Applies-to Doc. No." := AppliesToDocNo;
        GenJournalLine.Modify();
    end;

    local procedure CreateGenJournal(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreateJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; JournalTemplateName: Code[10]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, JournalTemplateName);
        GenJournalBatch.Validate("Bal. Account Type", BalAccountType);
        GenJournalBatch.Validate("Bal. Account No.", BalAccountNo);
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateComputerCheckPmtLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; Amount: Decimal; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; CurrencyCode: Code[10])
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10)));
        BankAccount.Modify(true);

        CreateGenJournal(GenJournalLine, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Computer Check");
        GenJournalLine.Validate("Check Exported", true);
        GenJournalLine.Validate("Check Transmitted", true);
        GenJournalLine.Validate("Currency Code", CurrencyCode);

        GenJournalLine.Modify(true);
    end;

    local procedure CreateCurrencyWithRoundingPrecision(RoundingPrecision: Decimal): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 1, 1);
        Currency.Validate("Amount Rounding Precision", RoundingPrecision);
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure GetAmtRoundingPrecision(CurrencyCode: Code[10]): Decimal
    var
        Currency: Record Currency;
    begin
        if CurrencyCode <> '' then
            Currency.Get(CurrencyCode)
        else
            Currency.InitRoundingPrecision();
        exit(Currency."Amount Rounding Precision");
    end;

    local procedure PrintCheckForPaymentJournalLine(GenJournalLine: Record "Gen. Journal Line"; BalAccountType: Enum "Gen. Journal Account Type")
    var
        DocumentPrint: Codeunit "Document-Print";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        DocumentPrint.PrintCheck(GenJournalLine);
        GenJournalLine.ModifyAll("Bal. Account Type", BalAccountType, false);
    end;

    local procedure SendAndApprovePaymentJournalBatch(GenJournalLine: Record "Gen. Journal Line"; RecID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ApprovalsMgmt.TrySendJournalBatchApprovalRequest(GenJournalLine);
        UpdateApprovalEntryWithCurrUser(ApprovalEntry, RecID);
        Approve(ApprovalEntry);
    end;

    local procedure SendAndApprovePaymentJournalLine(var GenJournalLine: Record "Gen. Journal Line"; RecID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        GenJournalLine.SetRecFilter();
        ApprovalsMgmt.TrySendJournalLineApprovalRequests(GenJournalLine);
        UpdateApprovalEntryWithCurrUser(ApprovalEntry, RecID);
        Approve(ApprovalEntry);
    end;

    local procedure SetupGenJnlBatchApprovalWorkflowWithUsers()
    var
        UserSetup: Record "User Setup";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode());
        LibraryDocumentApprovals.SetupUsersForApprovals(UserSetup);
    end;

    local procedure SetupGenJnlLineApprovalWorkflowWithUsers()
    var
        UserSetup: Record "User Setup";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalLineApprovalWorkflowCode());
        LibraryDocumentApprovals.SetupUsersForApprovals(UserSetup);
    end;

    local procedure UpdateApprovalEntryWithCurrUser(var ApprovalEntry: Record "Approval Entry"; RecID: RecordID)
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RecID);
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(RecID);
    end;

    local procedure VerifyCheckLedgerEntry(EntryNo: Integer; OriginalEntryStatus: Option)
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.Get(EntryNo);  // Get Check Ledger Entry updated from VoidCheck function of Codeunit - CheckManagement.
        CheckLedgerEntry.TestField("Entry Status", CheckLedgerEntry."Entry Status"::Voided);
        CheckLedgerEntry.TestField("Original Entry Status", OriginalEntryStatus);
        CheckLedgerEntry.TestField(Open, false);
    end;

    local procedure VerifyCheckCaptionAndNumber(DocumentNo: Code[20]; CheckNumberCaption: Text)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CheckNoTextCaption', 'Check No' + '.');  // Not able to pass Symbol - '.', as part of constant hence taking it here.
        LibraryReportDataset.AssertElementWithValueExists(CheckNumberCaption, DocumentNo);
    end;

    local procedure VerifyPaymentJournalLineCreatedforCheck(GenJournalLine: Record "Gen. Journal Line"; BalAccountNo: Code[20])
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindLast();
        GenJournalLine.TestField("Account Type", GenJournalLine."Account Type"::"Bank Account");
        GenJournalLine.TestField("Account No.", BalAccountNo);
    end;

    local procedure VerifyReportedCheckAmount(GenJournalLine: Record "Gen. Journal Line"; ReportedAmount: Text)
    begin
        Assert.AreEqual(
          Format(Round(GenJournalLine.Amount, 1, '<')) +
          CopyStr(Format(0.01), 2, 1) +
          PadStr('', StrLen(Format(GetAmtRoundingPrecision(GenJournalLine."Currency Code"))) - 2, '0'),
          ReportedAmount,
          WrongCheckAmountErr);
    end;

    local procedure VerifyRestrictionRecordNotExisting(RecID: RecordID)
    var
        RestrictedRecord: Record "Restricted Record";
    begin
        RestrictedRecord.SetRange("Record ID", RecID);
        Assert.IsTrue(RestrictedRecord.IsEmpty, StrSubstNo(RestrictionRecordFoundErr, RecID));
    end;

    local procedure VerifyVendorLedgerEntryExists(GenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.SetRange(Open, true);
        Assert.IsFalse(VendorLedgerEntry.IsEmpty, StrSubstNo(RecordNotFoundErr, VendorLedgerEntry.TableCaption()));
    end;

    local procedure VerifyVendorLedgerEntryExistsWithExternalDocNo(GenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document Type", GenJournalLine."Document Type");
        VendorLedgerEntry.SetRange("External Document No.", GenJournalLine."Document No.");
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.SetRange(Open, true);
        Assert.IsFalse(VendorLedgerEntry.IsEmpty, StrSubstNo(RecordNotFoundErr, VendorLedgerEntry.TableCaption()));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CheckRequestPageHandler(var Check: TestRequestPage Check)
    begin
        FilterOnReportCheckRequestPage(Check, false, false);  // Reprint Checks - FALSE, One Check Per Vendor Per Document No - FALSE.
        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OneCheckPerVendorPerDocNoCheckRequestPageHandler(var Check: TestRequestPage Check)
    begin
        FilterOnReportCheckRequestPage(Check, true, true);  // Reprint Checks - TRUE, One Check Per Vendor Per Document No - TRUE.
        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StubCheckRequestPageHandler(var StubCheck: TestRequestPage "Check (Stub/Stub/Check)")
    begin
        FilterOnReportStubStubCheckRequestPage(StubCheck, false, false);  // Reprint Checks - FALSE, One Check Per Vendor Per Document No - FALSE.
        StubCheck.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DocumentNoStubCheckRequestPageHandler(var StubCheck: TestRequestPage "Check (Stub/Stub/Check)")
    var
        DocumentNo: Variant;
    begin
        FilterOnReportStubStubCheckRequestPage(StubCheck, false, false);  // Reprint Checks - FALSE, One Check Per Vendor Per Document No - FALSE.
        LibraryVariableStorage.Dequeue(DocumentNo);
        StubCheck.VoidGenJnlLine.SetFilter("Document No.", DocumentNo);
        StubCheck.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReprintStubCheckRequestPageHandler(var StubCheck: TestRequestPage "Check (Stub/Stub/Check)")
    begin
        FilterOnReportStubStubCheckRequestPage(StubCheck, true, false);  // Reprint Checks - TRUE, One Check Per Vendor Per Document No - FALSE.
        StubCheck.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CheckStubRequestPageHandler(var CheckStub: TestRequestPage "Check (Stub/Check/Stub)")
    begin
        FilterOnReportStubCheckStubRequestPage(CheckStub, false, false);  // Reprint Checks - FALSE, One Check Per Vendor Per Document No - FALSE.
        CheckStub.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DocumentNoCheckStubRequestPageHandler(var CheckStub: TestRequestPage "Check (Stub/Check/Stub)")
    var
        DocumentNo: Variant;
    begin
        FilterOnReportStubCheckStubRequestPage(CheckStub, false, false);  // Reprint Checks - FALSE, One Check Per Vendor Per Document No - FALSE.
        LibraryVariableStorage.Dequeue(DocumentNo);
        CheckStub.VoidGenJnlLine.SetFilter("Document No.", DocumentNo);
        CheckStub.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DocumentNoThreeChecksRequestPageHandler(var ThreeChecksperPage: TestRequestPage "Three Checks per Page")
    var
        DocumentNo: Variant;
    begin
        FilterOnReportThreeChecksRequestPage(ThreeChecksperPage, false, false);  // Reprint Checks - FALSE, One Check Per Vendor Per Document No - FALSE.
        LibraryVariableStorage.Dequeue(DocumentNo);
        ThreeChecksperPage.VoidGenJnlLine.SetFilter("Document No.", DocumentNo);
        ThreeChecksperPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReprintCheckStubRequestPageHandler(var CheckStub: TestRequestPage "Check (Stub/Check/Stub)")
    begin
        FilterOnReportStubCheckStubRequestPage(CheckStub, true, false);  // Reprint Checks - TRUE, One Check Per Vendor Per Document No - FALSE.
        CheckStub.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReprintThreeChecksRequestPageHandler(var ThreeChecksperPage: TestRequestPage "Three Checks per Page")
    begin
        FilterOnReportThreeChecksRequestPage(ThreeChecksperPage, true, false);  // Reprint Checks - TRUE, One Check Per Vendor Per Document No - FALSE.
        ThreeChecksperPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OneCheckPerVendorPerDocNoStubStubCheckRequestPageHandler(var StubCheck: TestRequestPage "Check (Stub/Stub/Check)")
    begin
        FilterOnReportStubStubCheckRequestPage(StubCheck, true, true);  // Reprint Checks - TRUE, One Check Per Vendor Per Document No - TRUE.
        StubCheck.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OneCheckPerVendorPerDocNoStubCheckStubRequestPageHandler(var CheckStub: TestRequestPage "Check (Stub/Check/Stub)")
    begin
        FilterOnReportStubCheckStubRequestPage(CheckStub, true, true); // Reprint Checks - TRUE, One Check Per Vendor Per Document No - TRUE.
        CheckStub.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OneCheckPerVendorPerDocNoCheckStubStubRequestPageHandler(var CheckStub: TestRequestPage "Check (Check/Stub/Stub)")
    begin
        FilterOnReportCheckStubStubRequestPage(CheckStub, true, true); // Reprint Checks - TRUE, One Check Per Vendor Per Document No - TRUE.
        CheckStub.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OneCheckPerVendorPerDocNoThreeChecksRequestPageHandler(var ThreeChecksperPage: TestRequestPage "Three Checks per Page")
    begin
        FilterOnReportThreeChecksRequestPage(ThreeChecksperPage, true, true); // Reprint Checks - TRUE, One Check Per Vendor Per Document No - TRUE.
        ThreeChecksperPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CheckTranslationManagementRequestPageHandler(var CheckTranslationManagement: TestRequestPage "Check Translation Management")
    var
        TestLanguage: Variant;
        TestOption: Option "Both Amounts and Dates";
    begin
        CheckTranslationManagement.TestOption.SetValue(TestOption::"Both Amounts and Dates");
        LibraryVariableStorage.Dequeue(TestLanguage);
        CheckTranslationManagement.TestLanguage.SetValue(TestLanguage);
        CheckTranslationManagement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ThreeChecksRequestPageHandler(var ThreeChecksperPage: TestRequestPage "Three Checks per Page")
    begin
        FilterOnReportThreeChecksRequestPage(ThreeChecksperPage, false, false);  // Reprint Checks - FALSE, One Check Per Vendor Per Document No - FALSE.
        ThreeChecksperPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure FilterOnReportThreeChecksRequestPage(var ThreeChecksperPage: TestRequestPage "Three Checks per Page"; ReprintChecks: Boolean; OneCheckPerVendorPerDocumentNo: Boolean)
    var
        BankAccount: Variant;
        JournalBatchName: Variant;
        JournalTemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccount);
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        ThreeChecksperPage.VoidGenJnlLine.SetFilter("Journal Template Name", JournalTemplateName);
        ThreeChecksperPage.VoidGenJnlLine.SetFilter("Journal Batch Name", JournalBatchName);
        ThreeChecksperPage.ReprintChecks.SetValue(ReprintChecks);
        ThreeChecksperPage.OneCheckPerVendorPerDocumentNo.SetValue(OneCheckPerVendorPerDocumentNo);
        ThreeChecksperPage.BankAccount.SetValue(BankAccount);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

