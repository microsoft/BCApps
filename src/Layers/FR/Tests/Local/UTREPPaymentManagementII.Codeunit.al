codeunit 144054 "UT REP Payment Management II"
{
    // 1 - 29. Purpose of test is to validate error for Report 10882 (Transfer), 10881 (Withdraw), 10880 (ETEBAC Files), 10862 (Suggest Vendor Payments FR), 10864 (Suggest Customer Payments) and 10872 (Duplicate parameter).
    // 30.     Purpose of test is to validate error for Report 10873 (Archive Payment Slips).
    // 31.     Purpose of test is to validate OnAfterGetRecord of Report 10872 (Duplicate Parameter).
    // 
    // Covers Test Cases for WI - 344968
    // ----------------------------------------------------------------------------------------------------------------------
    // Test Function Name
    // ----------------------------------------------------------------------------------------------------------------------
    // OnAfterGetRecordPmtHdrTransferError, OnAfterGetRecordPmtHdrWithdrawError, OnAfterGetRecordPmtHdrETEBACFilesError
    // OnAfterGetRecordPmtHdrAgencyCodeTransferError, OnAfterGetRecordPmtHdrBankBranchNoTransferError
    // OnAfterGetRecordPmtHdrBankAccountNoTransferError, OnAfterGetRecordPmtHdrCurrencyCodeTransferError
    // OnAfterGetRecordPmtHdrAgencyCodeWithdrawError, OnAfterGetRecordPmtHdrBankBranchNoWithdrawError
    // OnAfterGetRecordPmtHdrBankAccountNoWithdrawError, OnAfterGetRecordPmtHdrCurrencyCodeWithdrawError
    // OnAfterGetRecordPmtHdrAgencyCodeETEBACFilesError, OnAfterGetRecordPmtHdrBankBranchNoETEBACFilesError
    // OnAfterGetRecordPmtHdrBankAccountNoETEBACFilesError, OnAfterGetRecordPaymentLineTransferError
    // OnAfterGetRecordPaymentLineWithdrawError, OnAfterGetRecordPaymentLineETEBACFilesError
    // OnAfterGetRecordPmtLineBankBranchNoTransferError, OnAfterGetRecordPmtLineBankBranchNoWithdrawError
    // OnAfterGetRecordPmtLineBankAccountNoWithdrawError, OnAfterGetRecordPmtLineBankAccountNoTransferError
    // OnAfterGetRecordPmtLineBankBranchNoETEBACFilesError, OnAfterGetRecordPmtLineBankAccountNoETEBACFilesError
    // OnPreDataItemVendPmtDateSuggestVendPmtFRError, OnPreDataItemVendPostingDateSuggestVendPmtFRError
    // OnPreDataItemVendPmtDateSuggestCustPmtError, OnPreDataItemVendPostingDateSuggestCustPmtError
    // OnPreDataItemPmtClassDuplParameterError, OnAfterGetRecordPmtClassDuplParameterError
    // OnAfterGetRecordPmtClassNewNameDuplParameterError, OnPostReportArchivePaymentSlips
    // 
    // Covers Test Cases for WI - 345175
    // ----------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                        TFS ID
    // ----------------------------------------------------------------------------------------------------------------------
    // OnAfterGetRecordPaymentClassDuplicateParameter                                                            169524

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        ArchiveMsg: Label 'There is no Payment Header to archive.';
        DialogCap: Label 'Dialog';
        ValueMatchMsg: Label 'Value must be same.';

#if not CLEAN28
    [Test]
    [HandlerFunctions('TransferRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtHdrTransferError()
    begin
        // Purpose of test is to validate Payment Header - OnAfterGetRecord of Report 10882 (Transfer).
        // Verify actual error: "The RIB of the company's bank account is incorrect. Please verify before continuing."
        PaymentHeaderWithRIBCheckedFalse(REPORT::Transfer);
    end;
#endif

    [Test]
    [HandlerFunctions('WithdrawRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtHdrWithdrawError()
    begin
        // Purpose of test is to validate Payment Header - OnAfterGetRecord of Report 10881 (Withdraw).
        // Verify actual error: "The RIB of the company's bank account is incorrect. Please verify before continuing."
        PaymentHeaderWithRIBCheckedFalse(REPORT::Withdraw);
    end;

    [Test]
    [HandlerFunctions('ETEBACFilesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtHdrETEBACFilesError()
    begin
        // Purpose of test is to validate Payment Header - OnAfterGetRecord of Report 10880 (ETEBAC Files).
        // Verify actual error: "The RIB of the company's bank account is incorrect. Please verify before continuing."
        PaymentHeaderWithRIBCheckedFalse(REPORT::"ETEBAC Files");
    end;

    local procedure PaymentHeaderWithRIBCheckedFalse(ReportID: Integer)
    begin
        // Setup.
        Initialize();
        CreatePaymentHeader(false);  // RIBChecked as false.

        // Exercise.
        asserterror REPORT.Run(ReportID);

        // Verify.
        Assert.ExpectedErrorCode(DialogCap);
    end;

#if not CLEAN28
    [Test]
    [HandlerFunctions('TransferRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtHdrAgencyCodeTransferError()
    var
        PaymentHeader: Record "Payment Header";
    begin
        // Purpose of test is to validate error of Agency Code for Report 10882 (Transfer).
        // Verify actual error: "Bank Account No. is too long. Please verify before continuing."
        PaymentHeaderWithRIBCheckedTrue(REPORT::Transfer, PaymentHeader.FieldNo("Agency Code"), LibraryUTUtility.GetNewCode10());
    end;

    [Test]
    [HandlerFunctions('TransferRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtHdrBankBranchNoTransferError()
    var
        PaymentHeader: Record "Payment Header";
    begin
        // Purpose of test is to validate error of Bank Branch No for Report 10882 (Transfer).
        // Verify actual error: "The RIB of the company's bank account is incorrect. Please verify before continuing."
        PaymentHeaderWithRIBCheckedTrue(REPORT::Transfer, PaymentHeader.FieldNo("Bank Branch No."), LibraryUTUtility.GetNewCode10());
    end;

    [Test]
    [HandlerFunctions('TransferRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtHdrBankAccountNoTransferError()
    var
        PaymentHeader: Record "Payment Header";
    begin
        // Purpose of test is to validate error of Bank Account No for Report 10882 (Transfer).
        // Verify actual error: "The RIB of the company's bank account is incorrect. Please verify before continuing."
        PaymentHeaderWithRIBCheckedTrue(REPORT::Transfer, PaymentHeader.FieldNo("Bank Account No."), LibraryUTUtility.GetNewCode());
    end;

    [Test]
    [HandlerFunctions('TransferRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtHdrCurrencyCodeTransferError()
    var
        PaymentHeader: Record "Payment Header";
    begin
        // Purpose of test is to validate error of Currency Code for Report 10882 (Transfer).
        // Verify actual error: "You can only use currency code EUR."
        PaymentHeaderWithRIBCheckedTrue(REPORT::Transfer, PaymentHeader.FieldNo("Currency Code"), CreateCurrencyExchangeRate())
    end;
#endif

    [Test]
    [HandlerFunctions('WithdrawRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtHdrAgencyCodeWithdrawError()
    var
        PaymentHeader: Record "Payment Header";
    begin
        // Purpose of test is to validate error of Agency Code for Report 10881 (Withdraw).
        // Verify actual error: "Bank Account No. is too long. Please verify before continuing."
        PaymentHeaderWithRIBCheckedTrue(REPORT::Withdraw, PaymentHeader.FieldNo("Agency Code"), LibraryUTUtility.GetNewCode10())
    end;

    [Test]
    [HandlerFunctions('WithdrawRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtHdrBankBranchNoWithdrawError()
    var
        PaymentHeader: Record "Payment Header";
    begin
        // Purpose of test is to validate error of Bank Branch No for Report 10881 (Withdraw).
        // Verify actual error: "Bank Account No. is too long. Please verify before continuing."
        PaymentHeaderWithRIBCheckedTrue(REPORT::Withdraw, PaymentHeader.FieldNo("Bank Branch No."), LibraryUTUtility.GetNewCode10())
    end;

    [Test]
    [HandlerFunctions('WithdrawRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtHdrBankAccountNoWithdrawError()
    var
        PaymentHeader: Record "Payment Header";
    begin
        // Purpose of test is to validate error of Bank Account No for Report 10881 (Withdraw).
        // Verify actual error: "Bank Account No. is too long. Please verify before continuing."
        PaymentHeaderWithRIBCheckedTrue(REPORT::Withdraw, PaymentHeader.FieldNo("Bank Account No."), LibraryUTUtility.GetNewCode());
    end;

    [Test]
    [HandlerFunctions('WithdrawRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtHdrCurrencyCodeWithdrawError()
    var
        PaymentHeader: Record "Payment Header";
    begin
        // Purpose of test is to validate error of Currency Code for Report 10881 (Withdraw).
        // Verify actual error: "You can only use currency code EUR."
        PaymentHeaderWithRIBCheckedTrue(REPORT::Withdraw, PaymentHeader.FieldNo("Currency Code"), CreateCurrencyExchangeRate());
    end;

    [Test]
    [HandlerFunctions('ETEBACFilesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtHdrAgencyCodeETEBACFilesError()
    var
        PaymentHeader: Record "Payment Header";
    begin
        // Purpose of test is to validate error of Agency Code for Report 10880 (ETEBAC Files).
        // Verify actual error: "Bank Account No. is too long. Please verify before continuing."
        PaymentHeaderWithRIBCheckedTrue(REPORT::"ETEBAC Files", PaymentHeader.FieldNo("Agency Code"), LibraryUTUtility.GetNewCode10());
    end;

    [Test]
    [HandlerFunctions('ETEBACFilesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtHdrBankBranchNoETEBACFilesError()
    var
        PaymentHeader: Record "Payment Header";
    begin
        // Purpose of test is to validate error of Bank Branch No for Report 10880 (ETEBAC Files).
        // Verify actual error: "Bank Account No. is too long. Please verify before continuing."
        PaymentHeaderWithRIBCheckedTrue(REPORT::"ETEBAC Files", PaymentHeader.FieldNo("Bank Branch No."), LibraryUTUtility.GetNewCode10());
    end;

    [Test]
    [HandlerFunctions('ETEBACFilesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtHdrBankAccountNoETEBACFilesError()
    var
        PaymentHeader: Record "Payment Header";
    begin
        // Purpose of test is to validate error of Bank Account No for Report 10880 (ETEBAC Files).
        // Verify actual error: "Bank Account No. is too long. Please verify before continuing."
        PaymentHeaderWithRIBCheckedTrue(REPORT::"ETEBAC Files", PaymentHeader.FieldNo("Bank Account No."), LibraryUTUtility.GetNewCode());
    end;

    local procedure PaymentHeaderWithRIBCheckedTrue(ReportID: Integer; FieldNo: Integer; FieldValue: Code[20])
    begin
        // Setup.
        Initialize();
        UpdatePaymentHeader(CreatePaymentHeader(true), FieldNo, FieldValue);  // RIBChecked as true.

        // Exercise.
        asserterror REPORT.Run(ReportID);

        // Verify.
        Assert.ExpectedErrorCode(DialogCap);
    end;

#if not CLEAN28
    [Test]
    [HandlerFunctions('TransferRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPaymentLineTransferError()
    begin
        // Purpose of test is to validate Payment Line - OnAfterGetRecord of Report 10882 (Transfer).
        // Verify actual error: "The RIB of the vendor's bank account  is incorrect. Please verify before continuing."
        CreatePaymentLineAndRunReport(REPORT::Transfer, LibraryUTUtility.GetNewCode());
    end;
#endif

    [Test]
    [HandlerFunctions('WithdrawRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPaymentLineWithdrawError()
    begin
        // Purpose of test is to validate Payment Line - OnAfterGetRecord of Report 10881 (Withdraw).
        // Verify actual error: "The RIB of the company's bank account is incorrect. Please verify before continuing."
        CreatePaymentLineAndRunReport(REPORT::Withdraw, LibraryUTUtility.GetNewCode());
    end;

    [Test]
    [HandlerFunctions('ETEBACFilesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPaymentLineETEBACFilesError()
    begin
        // Purpose of test is to validate Payment Line - OnAfterGetRecord of Report 10880 (ETEBAC Files).
        // Verify actual error: "The RIB of the company's bank account is incorrect. Please verify before continuing."
        CreatePaymentLineAndRunReport(REPORT::"ETEBAC Files", CreateCustomer());
    end;

    local procedure CreatePaymentLineAndRunReport(ReportID: Integer; FieldValue: Code[20])
    begin
        // Setup.
        Initialize();
        CreatePaymentLine(FieldValue);

        // Exercise.
        asserterror REPORT.Run(ReportID);

        // Verify.
        Assert.ExpectedErrorCode(DialogCap);
    end;

#if not CLEAN28
    [Test]
    [HandlerFunctions('TransferRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtLineBankBranchNoTransferError()
    var
        PaymentLine: Record "Payment Line";
    begin
        // Purpose of test is to validate error of Bank Branch No for Report 10882 (Transfer).
        // Verify actual error: "The vendor's bank account number is too long. Please verify before continuing."
        CreateAndUpdatePaymentLine(PaymentLine.FieldNo("Bank Branch No."), REPORT::Transfer);
    end;
#endif

    [Test]
    [HandlerFunctions('WithdrawRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtLineBankBranchNoWithdrawError()
    var
        PaymentLine: Record "Payment Line";
    begin
        // Purpose of test is to validate error of Bank Branch No for Report 10881 (Withdraw).
        // Verify actual error: "Bank Account No. is too long. Please verify before continuing."
        CreateAndUpdatePaymentLine(PaymentLine.FieldNo("Bank Branch No."), REPORT::Withdraw);
    end;

    [Test]
    [HandlerFunctions('WithdrawRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtLineBankAccountNoWithdrawError()
    var
        PaymentLine: Record "Payment Line";
    begin
        // Purpose of test is to validate error of Bank Account No for Report 10881 (Withdraw).
        // Verify actual error: "Bank Account No. is too long. Please verify before continuing."
        CreateAndUpdatePaymentLine(PaymentLine.FieldNo("Bank Account No."), REPORT::Withdraw);
    end;

#if not CLEAN28
    [Test]
    [HandlerFunctions('TransferRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtLineBankAccountNoTransferError()
    var
        PaymentLine: Record "Payment Line";
    begin
        // Purpose of test is to validate error of Bank Account No for Report 10882 (Transfer).
        // Verify actual error: "The vendor's bank account number  is too long. Please verify before continuing."
        CreateAndUpdatePaymentLine(PaymentLine.FieldNo("Bank Account No."), REPORT::Transfer);
    end;
#endif

    [Test]
    [HandlerFunctions('ETEBACFilesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtLineBankBranchNoETEBACFilesError()
    var
        PaymentLine: Record "Payment Line";
    begin
        // Purpose of test is to validate error of Bank Account No for Report 10880 (ETEBAC Files).
        // Verify actual error: "Bank Account No. is too long. Please verify before continuing."
        CreateAndUpdatePaymentLine(PaymentLine.FieldNo("Bank Account No."), REPORT::"ETEBAC Files");
    end;

    [Test]
    [HandlerFunctions('ETEBACFilesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtLineBankAccountNoETEBACFilesError()
    var
        PaymentLine: Record "Payment Line";
    begin
        // Purpose of test is to validate error of Bank Branch No for Report 10880 (ETEBAC Files).
        // Verify actual error: "Bank Account No. is too long. Please verify before continuing."
        CreateAndUpdatePaymentLine(PaymentLine.FieldNo("Bank Branch No."), REPORT::"ETEBAC Files");
    end;

    local procedure CreateAndUpdatePaymentLine(FieldNo: Integer; ReportID: Integer)
    begin
        // Setup.
        Initialize();
        UpdatePaymentLine(CreatePaymentLine(CreateCustomer()), FieldNo, LibraryUTUtility.GetNewCode());

        // Exercise.
        asserterror REPORT.Run(ReportID);

        // Verify.
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsFRRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVendPmtDateSuggestVendPmtFRError()
    begin
        // Purpose of test is to validate error of Payment Date for Report 10862 (Suggest Vendor Payments FR).
        // Verify actual error: "Please enter the last payment date."
        RunMiscellaneousReportsAndVerifyError(0D, REPORT::"Suggest Vendor Payments FR", DialogCap);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsFRRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVendPostingDateSuggestVendPmtFRError()
    begin
        // Purpose of test is to validate error of Posting Date for Report 10862 (Suggest Vendor Payments FR).
        // Verify actual error: "Please enter the posting date."
        RunMiscellaneousReportsAndVerifyError(WorkDate(), REPORT::"Suggest Vendor Payments FR", DialogCap);
    end;

    [Test]
    [HandlerFunctions('SuggestCustomerPaymentsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVendPmtDateSuggestCustPmtError()
    begin
        // Purpose of test is to validate error of Payment Date for Report 10864 (Suggest Customer Payments).
        // Verify actual error: "Please enter the last payment date."
        RunMiscellaneousReportsAndVerifyError(0D, REPORT::"Suggest Customer Payments", DialogCap);
    end;

    [Test]
    [HandlerFunctions('SuggestCustomerPaymentsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVendPostingDateSuggestCustPmtError()
    begin
        // Purpose of test is to validate error of Posting Date for Report 10864 (Suggest Customer Payments).
        // Verify actual error: "Please enter the posting date."
        RunMiscellaneousReportsAndVerifyError(WorkDate(), REPORT::"Suggest Customer Payments", DialogCap);
    end;

    [Test]
    [HandlerFunctions('DuplicateParameterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemPmtClassDuplParameterError()
    begin
        // Purpose of test is to validate error of New Name for Report 10872 (Duplicate parameter).
        // Verify actual error: "You must precise a new name."
        RunMiscellaneousReportsAndVerifyError('', REPORT::"Duplicate parameter", DialogCap);
    end;

    [Test]
    [HandlerFunctions('DuplicateParameterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtClassDuplParameterError()
    begin
        // Purpose of test is to validate error of New Name for Report 10872 (Duplicate parameter).
        // Verify actual error: "The Payment Class already exists. Identification fields and values.'"
        RunMiscellaneousReportsAndVerifyError(LibraryUTUtility.GetNewCode(), REPORT::"Duplicate parameter", 'DB:RecordExists');
    end;

    [Test]
    [HandlerFunctions('DuplicateParameterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPmtClassNewNameDuplParameterError()
    begin
        // Purpose of test is to validate error of New Name for Report 10872 (Duplicate parameter).
        // Verify actual error: "The name you have put does already exist. Please put an other name."
        RunMiscellaneousReportsAndVerifyError(CreatePaymentClass(), REPORT::"Duplicate parameter", DialogCap);
    end;

    local procedure RunMiscellaneousReportsAndVerifyError(InputValue: Variant; ReportID: Integer; ErrorCode: Text[30])
    begin
        // Setup.
        Initialize();

        // Enqueue required for DuplicateParameterRequestPageHandler, SuggestVendorPaymentsFRRequestPageHandler and SuggestCustomerPaymentsRequestPageHandler.
        LibraryVariableStorage.Enqueue(InputValue);

        // Exercise.
        asserterror REPORT.Run(ReportID);

        // Verify.
        Assert.ExpectedErrorCode(ErrorCode);
    end;

    [Test]
    [HandlerFunctions('ArchivePaymentSlipsRequestPageHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPostReportArchivePaymentSlips()
    begin
        // Purpose of test is to validate error for Report 10873 (Archive Payment Slips).
        // Setup.
        Initialize();
        LibraryVariableStorage.Enqueue(CreatePaymentHeader(true));  // Enqueue Payment Header No for ArchivePaymentSlipsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Archive Payment Slips");

        // Verify: Verification is covered in MessageHandler.
    end;

    [Test]
    [HandlerFunctions('DuplicateParameterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPaymentClassDuplicateParameter()
    var
        PaymentClass: TestPage "Payment Class";
    begin
        // Purpose of test is to validate OnAfterGetRecord of Report 10872 (Duplicate Parameter).
        // Setup: Create Payment Class and assign value for duplicate class.
        Initialize();
        PaymentClass.OpenEdit();
        PaymentClass.FILTER.SetFilter(Code, CreatePaymentClass());
        LibraryVariableStorage.Enqueue(CopyStr(PaymentClass.Code.Value, 1, 4));  // Enqueue required for DuplicateParameterRequestPageHandler.

        // Exercise: Run Duplicate Parameter batch job report.
        PaymentClass.DuplicateParameter.Invoke();

        // Verify: Verify duplicate class with new name.
        PaymentClass.FILTER.SetFilter(Code, CopyStr(PaymentClass.Code.Value, 1, 4));
        PaymentClass.Code.AssertEquals(CopyStr(PaymentClass.Code.Value, 1, 4));
        PaymentClass.Close();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Insert();
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyExchangeRate(): Code[10]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate."Currency Code" := CreateCurrency();
        CurrencyExchangeRate."Exchange Rate Amount" := LibraryRandom.RandDec(10, 2);
        CurrencyExchangeRate."Relational Exch. Rate Amount" := LibraryRandom.RandDec(10, 2);
        CurrencyExchangeRate.Insert();
        exit(CurrencyExchangeRate."Currency Code");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreatePaymentClass(): Text[30]
    var
        PaymentClass: Record "Payment Class";
    begin
        PaymentClass.Code := LibraryUTUtility.GetNewCode();
        PaymentClass.Insert();
        exit(PaymentClass.Code);
    end;

    local procedure CreatePaymentHeader(RIBChecked: Boolean): Code[20]
    var
        PaymentHeader: Record "Payment Header";
    begin
        PaymentHeader."No." := LibraryUTUtility.GetNewCode();
        PaymentHeader."Payment Class" := LibraryUTUtility.GetNewCode();
        PaymentHeader."Account Type" := PaymentHeader."Account Type"::"Bank Account";
        PaymentHeader."National Issuer No." := CopyStr(LibraryUTUtility.GetNewCode10(), 6);  // National Issuer No should be less than 6 characters.
        PaymentHeader."RIB Checked" := RIBChecked;
        PaymentHeader.Insert();
        exit(PaymentHeader."No.");
    end;

    local procedure CreatePaymentLine(AccountNo: Code[20]): Code[20]
    var
        PaymentLine: Record "Payment Line";
    begin
        PaymentLine."No." := CreatePaymentHeader(true);  // RIBChecked as true.
        PaymentLine."Account Type" := PaymentLine."Account Type"::"Bank Account";
        PaymentLine."Account No." := AccountNo;
        PaymentLine."Bank Account No." := LibraryUTUtility.GetNewCode10();
        PaymentLine.Insert();
        exit(PaymentLine."No.");
    end;

    local procedure UpdatePaymentHeader(No: Code[20]; FieldNo: Integer; FieldValue: Code[20])
    var
        PaymentHeader: Record "Payment Header";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        PaymentHeader.Get(No);
        RecRef.GetTable(PaymentHeader);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(FieldValue);
        RecRef.SetTable(PaymentHeader);
        PaymentHeader.Modify();
    end;

    local procedure UpdatePaymentLine(No: Code[20]; FieldNo: Integer; FieldValue: Code[20])
    var
        PaymentLine: Record "Payment Line";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        PaymentLine.SetRange("No.", No);
        PaymentLine.FindFirst();
        RecRef.GetTable(PaymentLine);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(FieldValue);
        RecRef.SetTable(PaymentLine);
        PaymentLine.Modify();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ArchivePaymentSlipsRequestPageHandler(var ArchivePaymentSlips: TestRequestPage "Archive Payment Slips")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ArchivePaymentSlips."Payment Header".SetFilter("No.", No);
        ArchivePaymentSlips.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DuplicateParameterRequestPageHandler(var Duplicateparameter: TestRequestPage "Duplicate parameter")
    var
        NewName: Variant;
    begin
        LibraryVariableStorage.Dequeue(NewName);
        Duplicateparameter.NewName.SetValue(NewName);
        Duplicateparameter.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ETEBACFilesRequestPageHandler(var ETEBACFiles: TestRequestPage "ETEBAC Files")
    begin
        ETEBACFiles.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.AreEqual(Message, StrSubstNo(ArchiveMsg), ValueMatchMsg);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestCustomerPaymentsRequestPageHandler(var SuggestCustomerPayments: TestRequestPage "Suggest Customer Payments")
    var
        LastPaymentDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(LastPaymentDate);
        SuggestCustomerPayments.LastPaymentDate.SetValue(LastPaymentDate);
        SuggestCustomerPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsFRRequestPageHandler(var SuggestVendorPaymentsFR: TestRequestPage "Suggest Vendor Payments FR")
    var
        LastPaymentDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(LastPaymentDate);
        SuggestVendorPaymentsFR.LastPaymentDate.SetValue(LastPaymentDate);
        SuggestVendorPaymentsFR.AvailableAmountLCY.SetValue(LibraryRandom.RandDec(10, 2));
        SuggestVendorPaymentsFR.OK().Invoke();
    end;

#if not CLEAN28
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferRequestPageHandler(var Transfer: TestRequestPage Transfer)
    begin
        Transfer.OK().Invoke();
    end;
#endif

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WithdrawRequestPageHandler(var Withdraw: TestRequestPage Withdraw)
    begin
        Withdraw.OK().Invoke();
    end;
}

