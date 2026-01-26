codeunit 141040 "UT COD Electronic Payment"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Electronic Payment]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        DialogErr: Label 'Dialog';
        TransitNoTxt: Label '110000000';
        TestFieldErr: Label '%1 must have a value in %2';
        VendorTransitNumNotValidErr: Label 'The specified transit number %1 for vendor %2  is not valid.', Comment = '%1 the transit number, %2 The Vendor No.';
        TransitNumberIsNotValidErr: Label 'The specified transit number is not valid.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RunCheckAccountTypeCustomerGenJnlCheckLineError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate RunCheck function of Codeunit ID - 11 Gen. Jnl.-Check Line.

        // Setup: Create General Journal Line with Account Type Customer.
        RunCheckGenJnlCheckLine(GenJournalLine."Account Type"::Customer);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RunCheckAccountTypeBankAccountGenJnlCheckLineError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate RunCheck function of Codeunit ID - 11 Gen. Jnl.-Check Line.

        // Setup: Create General Journal Line with Account Type Bank Account.
        RunCheckGenJnlCheckLine(GenJournalLine."Account Type"::"Bank Account");
    end;

    local procedure RunCheckGenJnlCheckLine(AccountType: Enum "Gen. Journal Account Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        // Create General Journal Line.
        CreateGeneralJournalLine(GenJournalLine, AccountType, CreateBankAccount(CreateBankAccountPostingGroup(), '', 0, ''), false);

        // Exercise.
        asserterror GenJnlCheckLine.RunCheck(GenJournalLine);

        // Verify: Verify Actual error message: Check Transmitted must be equal to 'Yes' in Gen. Journal Line.
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RunGenJnlPostLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        // Purpose of the test is to validate OnRun Trigger of Codeunit ID - 12 Gen. Jnl.-Post Line.
        // Setup.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"Bank Account", CreateBankAccountUS(CreateBankAccountPostingGroup(), ''), true);  // Check Transmitted - TRUE.
        CreateCheckLedgerEntry(CheckLedgerEntry, GenJournalLine."Account No.", GenJournalLine."Document No.");

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Line", GenJournalLine);

        // Verify: Verify Entry Status changed from Transmitted to Posted on Check Ledger Entry.
        CheckLedgerEntry.Get(CheckLedgerEntry."Entry No.");
        CheckLedgerEntry.TestField("Entry Status", CheckLedgerEntry."Entry Status"::Posted);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure StartExportFileExportPaymentsIATError()
    var
        ExportPaymentsIAT: Codeunit "Export Payments (IAT)";
    begin
        // Purpose of the test is to validate StartExportFile function of Codeunit ID - 10093 Export Payments (IAT).
        // Setup.
        UpdateCompanyInformationFederalID();

        // Exercise.
        asserterror
          ExportPaymentsIAT.StartExportFile(
            CreateBankAccountUS(CreateBankAccountPostingGroup(), Format(LibraryRandom.RandInt(10))), LibraryUTUtility.GetNewCode10());

        // Verify: Verify Error Code, Actual error - Transit No. is not valid in Bank Account No.
        Assert.ExpectedErrorCode('NCLCSRTS:TableErrorStr');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure StartExportBatchExportPaymentsIATError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExportPaymentsIAT: Codeunit "Export Payments (IAT)";
    begin
        // Purpose of the test is to validate StartExportBatch function of Codeunit ID - 10093 Export Payments (IAT).
        // Exercise.
        asserterror ExportPaymentsIAT.StartExportBatch(GenJournalLine, LibraryUTUtility.GetNewCode10(), WorkDate());

        // Verify: Verify Error Code, Actual error - Cannot start export batch until an export file is started.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ExportElectronicPaymentExportPaymentsIATError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExportPaymentsIAT: Codeunit "Export Payments (IAT)";
    begin
        // Purpose of the test is to validate ExportElectronicPayment function of Codeunit ID - 10093 Export Payments (IAT).
        // Exercise.
        asserterror ExportPaymentsIAT.ExportElectronicPayment(GenJournalLine, LibraryRandom.RandDec(10, 2));

        // Verify: Verify Error Code, Actual error - Cannot export details until an export file is started.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EndExportBatchExportPaymentsIATError()
    var
        ExportPaymentsIAT: Codeunit "Export Payments (IAT)";
    begin
        // Purpose of the test is to validate EndExportBatch function of Codeunit ID - 10093 Export Payments (IAT).
        // Exercise.
        asserterror ExportPaymentsIAT.EndExportBatch(LibraryUTUtility.GetNewCode10());

        // Verify: Verify Error Code, Actual error - Cannot end export batch until an export file is started..
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EndExportFileExportPaymentsIATError()
    var
        ExportPaymentsIAT: Codeunit "Export Payments (IAT)";
    begin
        // Purpose of the test is to validate EndExportFile function of Codeunit ID - 10093 Export Payments (IAT).
        // Exercise.
        asserterror ExportPaymentsIAT.EndExportFile();

        // Verify: Verify Error Code, Actual error - Cannot end export file until an export file is started..
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure StartExportFilePathExportPaymentsIATError()
    var
        BankAccount: Record "Bank Account";
        ExportPaymentsIAT: Codeunit "Export Payments (IAT)";
        BankAccountNo: Code[20];
    begin
        // Purpose of the test is to validate StartExportFile function of Codeunit ID - 10093 Export Payments (IAT).

        // Setup: Create Bank Account with E-Pay Export File Path which don't have '\' in the path.
        UpdateCompanyInformationFederalID();
        BankAccountNo := CreateBankAccountUS(CreateBankAccountPostingGroup(), TransitNoTxt);  // Codeunit 10093, weight is hardcoded to '37137137', so the value is selected  to make 10 - Digit MOD 10 equal to 0.
        BankAccount.Get(BankAccountNo);
        BankAccount."E-Pay Export File Path" := 'C:';
        BankAccount.Modify();

        // Exercise.
        asserterror ExportPaymentsIAT.StartExportFile(BankAccountNo, LibraryUTUtility.GetNewCode10());

        // Verify: Verify Error Code, Actual error - E-Pay Export File Path in Bank Account is invalid.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure StartExportBatchCustomerTransitNoExportPaymentsIATError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExportPaymentsIAT: Codeunit "Export Payments (IAT)";
        BankAccountNo, CustomerNo, CustomerBankAccountCode : Code[20];
    begin
        // Purpose of the test is to validate StartExportBatch function of Codeunit ID - 10093 Export Payments (IAT).

        // Setup: Create Customer Bank Account without Transit No. Create General Journal Line with Account Type Customer.
        UpdateCompanyInformationFederalID();
        BankAccountNo := CreateBankAccountUS(CreateBankAccountPostingGroup(), TransitNoTxt);  // Codeunit 10093, weight is hardcoded to '37137137', so the value is selected  to make 10 - Digit MOD 10 equal to 0.

        CreateCustomerBankAccount(CustomerNo, CustomerBankAccountCode, '', '');

        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, CustomerBankAccountCode, true);  // Check Transmitted - TRUE.

        UpdateBankAccount(BankAccountNo);
        ExportPaymentsIAT.StartExportFile(BankAccountNo, LibraryUTUtility.GetNewCode10());

        // Exercise.
        asserterror ExportPaymentsIAT.StartExportBatch(GenJournalLine, LibraryUTUtility.GetNewCode10(), WorkDate());

        // Verify: Verify Error Code, Actual error -Transit No. is not valid in Customer Bank Account.
        Assert.ExpectedErrorCode('NCLCSRTS:TableErrorStr');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure StartExportBatchBalAccountCustomerExportPaymentsIATError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExportPaymentsIAT: Codeunit "Export Payments (IAT)";
        BankAccountNo, CustomerNo, CustomerBankAccountCode : Code[20];
    begin
        // Purpose of the test is to validate StartExportBatch function of Codeunit ID - 10093 Export Payments (IAT).

        // Setup: Create Customer Bank Account without Transit No. Create General Journal Line with Balance Account Type Customer.
        UpdateCompanyInformationFederalID();
        BankAccountNo := CreateBankAccountUS(CreateBankAccountPostingGroup(), TransitNoTxt);  // Codeunit 10093, weight is hardcoded to '37137137', so the value is selected  to make 10 - Digit MOD 10 equal to 0.

        CreateCustomerBankAccount(CustomerNo, CustomerBankAccountCode, '', '');

        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, CustomerBankAccountCode, true);  // Check Transmitted - TRUE.

        UpdateBalanceAccountOnGenJournalLine(
          GenJournalLine, GenJournalLine."Bal. Account Type"::Customer, CustomerNo);
        UpdateBankAccount(BankAccountNo);
        ExportPaymentsIAT.StartExportFile(BankAccountNo, LibraryUTUtility.GetNewCode10());

        // Exercise.
        asserterror ExportPaymentsIAT.StartExportBatch(GenJournalLine, LibraryUTUtility.GetNewCode10(), WorkDate());

        // Verify: Verify Error Code, Actual error -Transit No. is not valid in Customer Bank Account.
        Assert.ExpectedErrorCode('NCLCSRTS:TableErrorStr');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure StartExportBatchVendorTransitNoExportPaymentsIATError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExportPaymentsIAT: Codeunit "Export Payments (IAT)";
        BankAccountNo, VendorNo, VendorBankAccountCode : Code[20];
    begin
        // Purpose of the test is to validate StartExportBatch function of Codeunit ID - 10093 Export Payments (IAT).

        // Setup: Create Vendor Bank Account without Transit No. Create General Journal Line with Account Type Vendor.
        UpdateCompanyInformationFederalID();
        BankAccountNo := CreateBankAccountUS(CreateBankAccountPostingGroup(), TransitNoTxt);  // Codeunit 10093, weight is hardcoded to '37137137', so the value is selected  to make 10 - Digit MOD 10 equal to 0.

        CreateVendorBankAccount(VendorNo, VendorBankAccountCode, '', 'US');

        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, VendorBankAccountCode, true);  // Check Transmitted - TRUE.

        UpdateBankAccount(BankAccountNo);
        ExportPaymentsIAT.StartExportFile(BankAccountNo, LibraryUTUtility.GetNewCode10());

        // Exercise.
        asserterror ExportPaymentsIAT.StartExportBatch(GenJournalLine, LibraryUTUtility.GetNewCode10(), WorkDate());

        // Verify: Verify Error Code, Actual error -Transit No. is not valid in Vendor Bank Account.
        Assert.ExpectedError(StrSubstNo(VendorTransitNumNotValidErr, '', VendorNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure StartExportBatchBalAccountVendorExportPaymentsIATError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExportPaymentsIAT: Codeunit "Export Payments (IAT)";
        BankAccountNo, VendorNo, VendorBankAccountCode : Code[20];
    begin
        // Purpose of the test is to validate StartExportBatch function of Codeunit ID - 10093 Export Payments (IAT).

        // Setup: Create Vendor Bank Account without Transit No. Create General Journal Line with Balance Account Type Vendor.
        UpdateCompanyInformationFederalID();
        BankAccountNo := CreateBankAccountUS(CreateBankAccountPostingGroup(), TransitNoTxt);  // Codeunit 10093, weight is hardcoded to '37137137', so the value is selected  to make 10 - Digit MOD 10 equal to 0.

        CreateVendorBankAccount(VendorNo, VendorBankAccountCode, '', 'US');

        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, VendorBankAccountCode, true);  // Check Transmitted - TRUE.

        UpdateBalanceAccountOnGenJournalLine(GenJournalLine, GenJournalLine."Bal. Account Type"::Vendor, VendorNo);
        UpdateBankAccount(BankAccountNo);
        ExportPaymentsIAT.StartExportFile(BankAccountNo, LibraryUTUtility.GetNewCode10());

        // Exercise.
        asserterror ExportPaymentsIAT.StartExportBatch(GenJournalLine, LibraryUTUtility.GetNewCode10(), WorkDate());

        // Verify: Verify Error Code, Actual error -Transit No. is not valid in Vendor Bank Account.
        Assert.ExpectedError(StrSubstNo(VendorTransitNumNotValidErr, '', VendorNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure StartExportBatchBalAccountTypeExportPaymentsIATError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExportPaymentsIAT: Codeunit "Export Payments (IAT)";
        BankAccountNo: Code[20];
    begin
        // Purpose of the test is to validate StartExportBatch function of Codeunit ID - 10093 Export Payments (IAT).

        // Setup: Create General Journal Line with Account Type Bank Account.
        UpdateCompanyInformationFederalID();
        BankAccountNo := CreateBankAccountUS(CreateBankAccountPostingGroup(), TransitNoTxt);  // Codeunit 10093, weight is hardcoded to '37137137', so the value is selected  to make 10 - Digit MOD 10 equal to 0.
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::"Bank Account", BankAccountNo, true);  // Check Transmitted - TRUE.
        UpdateBankAccount(BankAccountNo);
        ExportPaymentsIAT.StartExportFile(BankAccountNo, LibraryUTUtility.GetNewCode10());

        // Exercise.
        asserterror ExportPaymentsIAT.StartExportBatch(GenJournalLine, LibraryUTUtility.GetNewCode10(), WorkDate());

        // Verify: Verify Error Code, Actual error - Either Account Type or Bal. Account Type must refer to either a Vendor or a Customer for an electronic payment.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure StartExportBatchBalAccountTypeTransactionCodeRBError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExportPaymentsRB: Codeunit "Export Payments (RB)";
    begin
        // Verify TestField "Transaction Code" Error in case of "Bank Payment Type" = "Electronic Payment-IAT"

        // Setup: Create General Journal Line with Account Type Bank Account.
        CreateGenJnlLineWithBalAccountType(GenJournalLine, GenJournalLine."Bank Payment Type"::"Electronic Payment-IAT", '');

        // Exercise.
        asserterror ExportPaymentsRB.StartExportFile(GenJournalLine."Account No.", GenJournalLine);

        Assert.ExpectedError(StrSubstNo(TestFieldErr, GenJournalLine.FieldCaption("Transaction Code"), GenJournalLine.TableCaption()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure StartExportBatchBalAccountTypeCompanyEntryDescrRBError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExportPaymentsRB: Codeunit "Export Payments (RB)";
    begin
        // Verify TestField "Company Entry Description" Error in case of "Bank Payment Type" = "Electronic Payment-IAT"

        // Setup: Create General Journal Line with Account Type Bank Account.
        CreateGenJnlLineWithBalAccountType(
          GenJournalLine, GenJournalLine."Bank Payment Type"::"Electronic Payment-IAT",
          CopyStr(LibraryUTUtility.GetNewCode10(), 1, MaxStrLen(GenJournalLine."Transaction Code")));

        // Exercise.
        asserterror ExportPaymentsRB.StartExportFile(GenJournalLine."Account No.", GenJournalLine);

        Assert.ExpectedError(
          StrSubstNo(TestFieldErr, GenJournalLine.FieldCaption("Company Entry Description"), GenJournalLine.TableCaption()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure StartExportBatchBalAccountTypeRB()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExportPaymentsRB: Codeunit "Export Payments (RB)";
    begin
        // Verify no errors when using "Bank Account Type" = "Electronic Payment" and empty fields "Transaction Code", "Company Entry Description"

        // Setup: Create General Journal Line with Account Type Bank Account.
        CreateGenJnlLineWithBalAccountType(GenJournalLine, GenJournalLine."Bank Payment Type"::"Electronic Payment", '');

        // Verify that there's no error during run StartExportFile
        ExportPaymentsRB.StartExportFile(GenJournalLine."Account No.", GenJournalLine);
    end;

    [Test]
    procedure ExportPaymentsACH_CheckVendorTransitNum()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        ExportPaymentsACH: Codeunit "Export Payments (ACH)";
        VendorNo: Code[20];
        VendorBankAccountNo: Code[20];
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 395186] COD 10090 "Export Payments (ACH)".CheckVendorTransitNum() checks "Transit No." only for US vendor bank account

        // Positive US case
        CreateVendorBankAccount(VendorNo, VendorBankAccountNo, TransitNoTxt, 'US');
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, VendorBankAccountNo, false);
        ExportPaymentsACH.CheckVendorTransitNum(GenJournalLine, VendorNo, Vendor, VendorBankAccount, true);

        // Positive CA case
        VendorBankAccount.Get(VendorNo, VendorBankAccountNo);
        VendorBankAccount."Transit No." := '123456789';
        VendorBankAccount."Country/Region Code" := 'CA';
        VendorBankAccount.Modify();
        ExportPaymentsACH.CheckVendorTransitNum(GenJournalLine, VendorNo, Vendor, VendorBankAccount, true);

        // Negative US case
        VendorBankAccount."Country/Region Code" := 'US';
        VendorBankAccount.Modify();
        asserterror ExportPaymentsACH.CheckVendorTransitNum(GenJournalLine, VendorNo, Vendor, VendorBankAccount, true);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(VendorTransitNumNotValidErr, VendorBankAccount."Transit No.", Vendor."No."));
    end;

    [Test]
    procedure ExportEFTIAT_StartExportFile_TransitNumCheckDigit()
    var
        BankAccount: Record "Bank Account";
        ACHUSHeader: Record "ACH US Header";
        EFTValues: Codeunit "EFT Values";
        ExportEFTIAT: Codeunit "Export EFT (IAT)";
    begin
        // [FEATURE] [UT] [Bank Account]
        // [SCENARIO 395186] COD 10097 "Export EFT (IAT)".StartExportFile() checks "Transit No." only for US bank account
        UpdateCompanyInformationFederalID();

        ACHUSHeader."Data Exch. Entry No." := 0;
        ACHUSHeader.Insert();

        // Positive US case
        BankAccount.Get(CreateBankAccount(CreateBankAccountPostingGroup(), TransitNoTxt, BankAccount."Export Format"::US, 'US'));
        ExportEFTIAT.StartExportFile(BankAccount."No.", '', 0, EFTValues);

        // Positive CA case
        BankAccount."Transit No." := '123456789';
        BankAccount."Country/Region Code" := 'CA';
        BankAccount.Modify();
        ExportEFTIAT.StartExportFile(BankAccount."No.", '', 0, EFTValues);

        // Negative US case
        BankAccount."Country/Region Code" := 'US';
        BankAccount.Modify();
        asserterror ExportEFTIAT.StartExportFile(BankAccount."No.", '', 0, EFTValues);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(TransitNumberIsNotValidErr);
    end;

    [Test]
    procedure ExportEFTIAT_GetRecipientData_VendorTransitNumCheckDigit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        ExportEFTIAT: Codeunit "Export EFT (IAT)";
        VendorNo: Code[20];
        VendorBankAccountNo: Code[20];
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 395186] COD 10097 "Export EFT (IAT)".GetRecipientData() checks "Transit No." only for US vendor bank account

        // Positive US case
        CreateVendorBankAccount(VendorNo, VendorBankAccountNo, TransitNoTxt, 'US');
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, VendorBankAccountNo, false);
        UpdateEFTExportWorksetFromGenJnlLine(TempEFTExportWorkset, GenJournalLine);
        ExportEFTIAT.GetRecipientData(TempEFTExportWorkset);

        // Positive CA case
        VendorBankAccount.Get(VendorNo, VendorBankAccountNo);
        VendorBankAccount."Transit No." := '123456789';
        VendorBankAccount."Country/Region Code" := 'CA';
        VendorBankAccount.Modify();
        ExportEFTIAT.GetRecipientData(TempEFTExportWorkset);

        // Negative US case
        VendorBankAccount."Country/Region Code" := 'US';
        VendorBankAccount.Modify();
        asserterror ExportEFTIAT.GetRecipientData(TempEFTExportWorkset);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(TransitNumberIsNotValidErr);
    end;

    [Test]
    procedure ExportEFTIAT_GetRecipientData_CustomerTransitNumCheckDigit()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerBankAccount: Record "Customer Bank Account";
        TempEFTExportWorkset: Record "EFT Export Workset" temporary;
        ExportEFTIAT: Codeunit "Export EFT (IAT)";
        CustomerNo: Code[20];
        CustomerBankAccountNo: Code[20];
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 395186] COD 10097 "Export EFT (IAT)".GetRecipientData() checks "Transit No." only for US customer bank account

        // Positive US case
        CreateCustomerBankAccount(CustomerNo, CustomerBankAccountNo, TransitNoTxt, 'US');
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, CustomerBankAccountNo, false);
        UpdateEFTExportWorksetFromGenJnlLine(TempEFTExportWorkset, GenJournalLine);
        ExportEFTIAT.GetRecipientData(TempEFTExportWorkset);

        // Positive CA case
        CustomerBankAccount.Get(CustomerNo, CustomerBankAccountNo);
        CustomerBankAccount."Transit No." := '123456789';
        CustomerBankAccount."Country/Region Code" := 'CA';
        CustomerBankAccount.Modify();
        ExportEFTIAT.GetRecipientData(TempEFTExportWorkset);

        // Negative US case
        CustomerBankAccount."Country/Region Code" := 'US';
        CustomerBankAccount.Modify();
        asserterror ExportEFTIAT.GetRecipientData(TempEFTExportWorkset);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(TransitNumberIsNotValidErr);
    end;

    local procedure CreateGenJnlLineWithBalAccountType(var GenJournalLine: Record "Gen. Journal Line"; BankPaymentType: Enum "Bank Payment Type"; TransactionCode: Code[3])
    var
        BankAccountNo: Code[20];
    begin
        UpdateCompanyInformationFederalID();
        BankAccountNo := CreateBankAccountCA(CreateBankAccountPostingGroup(), TransitNoTxt);  // Codeunit 10093, weight is hardcoded to '37137137', so the value is selected  to make 10 - Digit MOD 10 equal to 0.
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::"Bank Account", BankAccountNo, true);  // Check Transmitted - TRUE.
        UpdateBankAccount(BankAccountNo);
        GenJournalLine."Bank Payment Type" := BankPaymentType;
        GenJournalLine."Transaction Code" := TransactionCode;
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CheckTransmitted: Boolean)
    begin
        SetGeneralJournalLine(GenJournalLine, AccountType, AccountNo, CheckTransmitted);

        GenJournalLine.Insert();
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; RecipientBankAccountNo: Code[20]; CheckTransmitted: Boolean)
    begin
        SetGeneralJournalLine(GenJournalLine, AccountType, AccountNo, CheckTransmitted);

        GenJournalLine."Recipient Bank Account" := RecipientBankAccountNo;

        GenJournalLine.Insert();
    end;

    local procedure SetGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CheckTransmitted: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine."Bal. Account No." := AccountNo;
        GenJournalLine."System-Created Entry" := true;
        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Electronic Payment";
        GenJournalLine."Check Exported" := true;
        GenJournalLine."Check Transmitted" := CheckTransmitted;
    end;

    local procedure CreateCheckLedgerEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountNo: Code[20]; CheckNo: Code[20])
    begin
        CheckLedgerEntry."Entry No." := SelectCheckLedgerEntryNo();
        CheckLedgerEntry."Bank Account No." := BankAccountNo;
        CheckLedgerEntry."Entry Status" := CheckLedgerEntry."Entry Status"::Transmitted;
        CheckLedgerEntry."Check No." := CheckNo;
        CheckLedgerEntry.Insert();
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateBankAccountUS(BankAccPostingGroup: Code[20]; TransitNo: Text[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        exit(CreateBankAccount(BankAccPostingGroup, TransitNo, BankAccount."Export Format"::US, ''));
    end;

    local procedure CreateBankAccountCA(BankAccPostingGroup: Code[20]; TransitNo: Text[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        exit(CreateBankAccount(BankAccPostingGroup, TransitNo, BankAccount."Export Format"::CA, ''));
    end;

    local procedure CreateBankAccount(BankAccPostingGroup: Code[20]; TransitNo: Text[20]; ExportFormat: Option; CountryRegionCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount."Bank Acc. Posting Group" := BankAccPostingGroup;
        BankAccount."Export Format" := ExportFormat;
        BankAccount."Transit No." := TransitNo;
        BankAccount."Client No." := LibraryUTUtility.GetNewCode10();
        BankAccount."Client Name" := LibraryUTUtility.GetNewCode10();
        BankAccount."Input Qualifier" := LibraryUTUtility.GetNewCode10();
        BankAccount."Country/Region Code" := CountryRegionCode;
        BankAccount."Last E-Pay Export File Name" := LibraryUTUtility.GetNewCode10();
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateBankAccountPostingGroup(): Code[20]
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        BankAccountPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        BankAccountPostingGroup."G/L Account No." := CreateGLAccount();
        BankAccountPostingGroup.Insert();
        exit(BankAccountPostingGroup.Code);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate.Insert();

        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        GenJournalBatch.Insert();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateCustomerBankAccount(var CustomerNo: Code[20]; var CustomerBankAccountCode: Code[20]; TransitNo: Text[20]; CountryRegionCode: Code[10])
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount."Customer No." := CreateCustomer();
        CustomerBankAccount.Code := LibraryUTUtility.GetNewCode10();
        CustomerBankAccount."Use for Electronic Payments" := true;
        CustomerBankAccount."Transit No." := TransitNo;
        CustomerBankAccount."Country/Region Code" := CountryRegionCode;
        CustomerBankAccount."Bank Account No." := LibraryUTUtility.GetNewCode10();
        CustomerBankAccount.Insert();

        CustomerNo := CustomerBankAccount."Customer No.";
        CustomerBankAccountCode := CustomerBankAccount.Code
    end;

    local procedure CreateVendorBankAccount(var VendorNo: Code[20]; var VendorBankAccountCode: Code[20]; TransitNo: Text[20]; CountryRegionCode: Code[10])
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount."Vendor No." := CreateVendor();
        VendorBankAccount.Code := LibraryUTUtility.GetNewCode10();
        VendorBankAccount."Use for Electronic Payments" := true;
        VendorBankAccount."Transit No." := TransitNo;
        VendorBankAccount."Country/Region Code" := CountryRegionCode;
        VendorBankAccount."Bank Account No." := LibraryUTUtility.GetNewCode10();
        VendorBankAccount.Insert();

        VendorNo := VendorBankAccount."Vendor No.";
        VendorBankAccountCode := VendorBankAccount.Code;
    end;

    local procedure SelectCheckLedgerEntryNo(): Integer
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        if CheckLedgerEntry.FindLast() then
            exit(CheckLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure UpdateCompanyInformationFederalID()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Federal ID No." := LibraryUTUtility.GetNewCode();
        CompanyInformation.Modify();
    end;

    local procedure UpdateBankAccount(BankAccountNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountNo);
        BankAccount."E-Pay Export File Path" := TemporaryPath;
        BankAccount."Last E-Pay Export File Name" := Format(LibraryUTUtility.GetNewCode());
        BankAccount."Last ACH File ID Modifier" := Format(LibraryRandom.RandIntInRange(1, 9));
        BankAccount.Modify();
    end;

    local procedure UpdateBalanceAccountOnGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20])
    begin
        GenJournalLine."Bal. Account Type" := BalAccountType;
        GenJournalLine."Bal. Account No." := BalAccountNo;
        GenJournalLine.Modify();
    end;

    local procedure UpdateEFTExportWorksetFromGenJnlLine(var EFTExportWorkset: Record "EFT Export Workset"; GenJournalLine: Record "Gen. Journal Line")
    begin
        EFTExportWorkset."Journal Template Name" := GenJournalLine."Journal Template Name";
        EFTExportWorkset."Journal Batch Name" := GenJournalLine."Journal Batch Name";
        EFTExportWorkset."Line No." := GenJournalLine."Line No.";
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::Vendor then
            EFTExportWorkset."Account Type" := EFTExportWorkset."Account Type"::Vendor
        else
            EFTExportWorkset."Account Type" := EFTExportWorkset."Account Type"::Customer;
        EFTExportWorkset."Account No." := GenJournalLine."Account No.";
    end;
}

