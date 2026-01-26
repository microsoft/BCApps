codeunit 144012 "UT TAB Cash Bank Giro"
{
    // 1:     Purpose of the test is to validate Error Journal Template Name without Balance Account No in CBG Statement table.
    // 2-3:   Purpose of the test is to validate Error Check Balance with Type Bank/Giro and Cash with Process Canceled CBG Statement table.
    // 4-5:   Purpose of the test is to validate Error Process Statement as Gen Journal with Type Bank/Giro and Cash in  CBG Statement table.
    // 6-7:   Purpose of the test is to validate Error Account No with Blocked Customer and Vendor in CBG Statement Line table.
    // 8:     Purpose of the test is to validate Error Applies To ID  in when creating two statement line in CBG Statement Line table.
    // 9:     Purpose of the test is to validate Error Identification with different currency in CBG Statement Line table and Payment History Line table.
    // 10-12: Purpose of the test is to validate Error Calculate VAT with VAT Posting Type, VAT Prod. Posting Group and VAT Bus Posting Group  CBG Statement Line table.
    // 13-14: Purpose of the test is to validate Error Calculate VAT with VAT Calculation Type Full VAT for Sale and Purchase CBG Statement Line table.
    // 15:    Purpose of the test is to validate Error Calculate VAT with VAT Calculation Type Sales tax in CBG Statement Table.
    // 
    // Purpose of the test is to validate Error for Customer Bank Account on Sales Documents (Quote, Order, Return Order, Invoice and Credit Memo) without Customer No.
    // Covers Test Cases: 342916
    // --------------------------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                                               TFS ID
    // --------------------------------------------------------------------------------------------------------------------------------------------------------
    // OnInsertBalanceAccNoWithoutTemplateCBGStatementErr, CheckBalanceTypeBankCBGStatementError, CheckBalanceTypeCashCBGStatementError                 154651
    // ProcessStatementAsGenJournalTypeBankCBGStmtErr, ProcessStatementAsGenJournalTypeCashCBGStmtErr
    // OnValidateAccountNoWithBlockedCustCBGStmtLineErr,OnValidateAccountNoWithBlockedVendCBGStmtLineErr
    // OnValidateAppliesToIDCBGStatementLineError, OnValidateIdentificationCurrencyCBGStmtLineError,
    // CalculateVATWithVATPostTypeAndVATBusPostGrErr, CalculateVATWithVATPostTypeAndVATProdPostGrErr, CalculateVATWithVATBusPostGrAndVATProdPostGrErr
    // CalculateVATWithFullVATTypeSaleError, CalculateVATWithFullVATTypePurchError, CalculateVATWithFullVATSalesTaxError

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        OpeningBalanceQst: Label 'The opening balance';
        PostingQst: Label 'Do you want to';
        CannotCreateDocWhenCustBlockedErr: Label 'You cannot create this type of document when Customer %1 is blocked with type %2';
        CannotCreateDocWhenVendBlockedErr: Label 'You cannot create this type of document when Vendor %1 is blocked with type %2';
        PrivacyBlockedCustErr: Label 'You cannot create this type of document when Customer %1 is blocked for privacy.';
        PrivacyBlockedVendErr: Label 'You cannot create this type of document when Vendor %1 is blocked for privacy.';
        BlockedEmplForJnrlErr: Label 'You cannot create this document because employee %1 is blocked due to privacy.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertBalanceAccNoWithoutTemplateCBGStatementErr()
    var
        CBGStatement: Record "CBG Statement";
    begin
        // Purpose of this test to verify Journal Template Name without Balance Account No in CBG Statement table.

        // Setup: Create Journal Template.
        Initialize();
        CBGStatement."Journal Template Name" := CreateJournalTemplate('');

        // Exercise.
        asserterror CBGStatement.Insert(true);

        // Verify: Verify error code, actual error is 'Bal. Account No. must have a value in Gen. Journal Template: Name=125457X001. It cannot be zero or empty.', on trigger OnInsert Balance Account No of CBG Statement table.
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckBalanceTypeBankCBGStatementError()
    var
        CBGStatement: Record "CBG Statement";
    begin
        // Purpose of this test to verify Check Balance with Type Bank/Giro with Process Canceled CBG Statement table.
        CheckBalanceTypeCBGStatement(CBGStatement.Type::"Bank/Giro");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckBalanceTypeCashCBGStatementError()
    var
        CBGStatement: Record "CBG Statement";
    begin
        // Purpose of this test to verify Check Balance with Type Cash with Process Canceled CBG Statement table.
        CheckBalanceTypeCBGStatement(CBGStatement.Type::Cash);
    end;

    local procedure CheckBalanceTypeCBGStatement(Type: Option)
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Setup: Create CBG Statement.
        Initialize();
        CreateCBGStatement(
          CBGStatement, CBGStatementLine, Type, CBGStatementLine."Account Type"::Customer,
          CreateCustomerLedgerEntry(), CreateCurrency());

        // Exercise.
        asserterror CBGStatement.CheckBalance();

        // Verify: Verify error code, actual error is 'Process canceled, check the statement lines or correct the opening and the closing balance.', on Check Balance of CBG Statement table.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ProcessStatementAsGenJournalTypeBankCBGStmtErr()
    var
        CBGStatement: Record "CBG Statement";
    begin
        // Purpose of this test to verify Process Statement as Gen Journal  with Type Bank/Giro CBG Statement table.
        ProcessStatementAsGenJournalTypeCBGStatement(CBGStatement.Type::"Bank/Giro");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ProcessStatementAsGenJournalTypeCashCBGStmtErr()
    var
        CBGStatement: Record "CBG Statement";
    begin
        // Purpose of this test to verify Process Statement as Gen Journal with Type Cash CBG Statement table.
        ProcessStatementAsGenJournalTypeCBGStatement(CBGStatement.Type::Cash);
    end;

    local procedure ProcessStatementAsGenJournalTypeCBGStatement(Type: Option)
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Setup: Create CBG Statement.
        Initialize();
        CreateCBGStatement(
          CBGStatement, CBGStatementLine, Type, CBGStatementLine."Account Type"::Customer,
          CreateCustomerLedgerEntry(), '');

        // Exercise.
        asserterror CBGStatement.ProcessStatementASGenJournal();

        // Verify: Verify error code, actual error is "Bal. Account Type must be ""Bank"" in/General Journal Template when/the identification must be applied.", on Check Balance of CBG Statement table.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAccountNoWithBlockedCustCBGStmtLineErr()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        Customer: Record Customer;
    begin
        // [SCENARIO 474117] Validate Account No with Blocked:All Customer in CBG Statement Line table.
        Initialize();
        CreateCBGStatement(CBGStatement, CBGStatementLine, CBGStatement.Type::"Bank/Giro", CBGStatementLine."Account Type"::Customer, '', '');
        CreateBlockedCustomer(Customer, Customer.Blocked::All, false);
        asserterror CBGStatementLine.Validate("Account No.", Customer."No.");

        // [THEN] "You cannot create this type of document when Customer is blocked with type All".
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(CannotCreateDocWhenCustBlockedErr, Customer."No.", Customer.Blocked::All));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAccountNoWithBlockedInvoiceCustCBGStmtLineErr()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        Customer: Record Customer;
    begin
        // [SCENARIO 474117] Validate Account No with Blocked:Invoice Customer in CBG Statement Line table.
        Initialize();
        CreateCBGStatement(CBGStatement, CBGStatementLine, CBGStatement.Type::"Bank/Giro", CBGStatementLine."Account Type"::Customer, '', '');
        CreateBlockedCustomer(Customer, Customer.Blocked::Invoice, false);
        CBGStatementLine.Validate("Account No.", Customer."No.");

        // [THEN] Allowed to use Customer in the line.
        CBGStatementLine.TestField("Account No.", Customer."No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAccountNoWithBlockedVendCBGStmtLineErr()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 474117] Validate Account No with Blocked:All Vendor in CBG Statement Line table.
        Initialize();
        CreateCBGStatement(CBGStatement, CBGStatementLine, CBGStatement.Type::"Bank/Giro", CBGStatementLine."Account Type"::Vendor, '', '');
        CreateBlockedVendor(Vendor, Vendor.Blocked::All, false);
        asserterror CBGStatementLine.Validate("Account No.", Vendor."No.");
        // [THEN] "You cannot create this type of document when Vendor is blocked with type All".
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(CannotCreateDocWhenVendBlockedErr, Vendor."No.", Vendor.Blocked::All));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAccountNoWithBlockedPaymentVendCBGStmtLineErr()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 474117] Validate Account No with Blocked:Payment Vendor in CBG Statement Line table.
        Initialize();
        CreateCBGStatement(CBGStatement, CBGStatementLine, CBGStatement.Type::"Bank/Giro", CBGStatementLine."Account Type"::Vendor, '', '');
        CreateBlockedVendor(Vendor, Vendor.Blocked::Payment, false);
        asserterror CBGStatementLine.Validate("Account No.", Vendor."No.");
        // [THEN] "You cannot create this type of document when Vendor is blocked with type Payment".
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(CannotCreateDocWhenVendBlockedErr, Vendor."No.", Vendor.Blocked::Payment));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAccountNoWithPrivacyBlockedCustCBGStmtLineErr()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        Customer: Record Customer;
    begin
        // [SCENARIO 474117] Validate Account No with Privacy Blocked Customer in CBG Statement Line table.
        Initialize();
        CreateCBGStatement(CBGStatement, CBGStatementLine, CBGStatement.Type::"Bank/Giro", CBGStatementLine."Account Type"::Customer, '', '');
        CreateBlockedCustomer(Customer, Customer.Blocked::" ", true);
        asserterror CBGStatementLine.Validate("Account No.", Customer."No.");

        // [THEN] "You cannot create this type of document when Customer has privacy blocked true.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(PrivacyBlockedCustErr, Customer."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAccountNoWithPrivacyBlockedVendCBGStmtLineErr()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 474117] Validate Account No with Privacy Blocked Vendor in CBG Statement Line table.
        Initialize();
        CreateCBGStatement(CBGStatement, CBGStatementLine, CBGStatement.Type::"Bank/Giro", CBGStatementLine."Account Type"::Vendor, '', '');
        CreateBlockedVendor(Vendor, Vendor.Blocked::" ", true);
        asserterror CBGStatementLine.Validate("Account No.", Vendor."No.");

        // [THEN] "You cannot create this type of document when Vendor has privacy blocked true.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(PrivacyBlockedVendErr, Vendor."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAccountNoWithPrivacyBlockedEmployeeCBGStmtLineErr()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        Employee: Record Employee;
    begin
        // [SCENARIO 474117] Validate Account No with Privacy Blocked Employee in CBG Statement Line table.
        Initialize();
        CreateCBGStatement(CBGStatement, CBGStatementLine, CBGStatement.Type::"Bank/Giro", CBGStatementLine."Account Type"::Employee, '', '');
        Employee."No." := LibraryUTUtility.GetNewCode();
        Employee."Privacy Blocked" := true;
        Employee.Insert();
        asserterror CBGStatementLine.Validate("Account No.", Employee."No.");

        // [THEN] "You cannot create this type of document when Employee has privacy blocked true.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(BlockedEmplForJnrlErr, Employee."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateAppliesToIDCBGStatementLineError()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Purpose of this test to validate Applies To ID  in when creating two statement line in CBG Statement Line table.
        Initialize();
        CreateCBGStatement(
          CBGStatement, CBGStatementLine, CBGStatement.Type::"Bank/Giro",
          CBGStatementLine."Account Type"::Customer, CreateCustomerLedgerEntry(), '');

        // Exercise.
        asserterror CreateCBGStatementLine(CBGStatementLine, CBGStatementLine."Account Type"::Customer,
            CreateCustomerLedgerEntry(), CBGStatement."Journal Template Name", CBGStatement."No.");

        // Verify: Verify error code, actual error is "Applies-to ID is used before in  1 line 1", on Check Balance of CBG Statement Line table.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateIdentificationCurrencyCBGStmtLineError()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Purpose of this test to validate Identification with different currency in CBG Statement Line table and Payment History Line table.
        Initialize();
        CreateCBGStatement(
          CBGStatement, CBGStatementLine, CBGStatement.Type::"Bank/Giro",
          CBGStatementLine."Account Type"::Customer, CreateCustomerLedgerEntry(), CreateCurrency());
        CreatePaymentHistory(
          CBGStatementLine."Statement No.", CBGStatementLine.Identification, CBGStatementLine."Account No.");

        // Exercise.
        asserterror CBGStatementLine.Validate(Identification);

        // Verify: Verify error code, actual error is "The currency of the bank journal ""131836X027"" and the currency of the payment history line ""131836X031"" must be equal.", on Check Balance of CBG Statement Line table.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalculateVATWithVATPostTypeAndVATBusPostGrErr()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Purpose of this test to Calculate VAT with VAT Posting Type and  VAT Bus Posting Group CBG Statement Line table.
        Initialize();
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateCBGStatement(
          CBGStatement, CBGStatementLine, CBGStatement.Type::"Bank/Giro", CBGStatementLine."Account Type"::Customer, CreateCustomer(), '');
        CBGStatementLine."VAT Type" := CBGStatementLine."VAT Type"::Sale;
        CBGStatementLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";

        // Exercise.
        asserterror CBGStatementLine.Validate("VAT Prod. Posting Group", '');  // Blank VAT Prod. Posting Group.

        // Verify: Verify error code, actual error is "You can only apply VAT when Account Type = G/L Account", CBG Statement Line table.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalculateVATWithVATPostTypeAndVATProdPostGrErr()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Purpose of this test to Calculate VAT with VAT Posting Type and VAT Prod. Posting Group CBG Statement Line table.
        Initialize();
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateCBGStatement(
          CBGStatement, CBGStatementLine, CBGStatement.Type::"Bank/Giro", CBGStatementLine."Account Type"::Customer, CreateCustomer(), '');
        CBGStatementLine."VAT Type" := CBGStatementLine."VAT Type"::Sale;
        CBGStatementLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";

        // Exercise.
        asserterror CBGStatementLine.Validate("VAT Bus. Posting Group", '');  // Blank VAT Bus. Posting Group.

        // Verify: Verify error code, actual error is "You can only apply VAT when Account Type = G/L Account", CBG Statement Line table.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalculateVATWithVATBusPostGrAndVATProdPostGrErr()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Purpose of this test to Calculate VAT with VAT Bus Posting Group and VAT Prod. Posting Group CBG Statement Line table.
        Initialize();
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateCBGStatement(
          CBGStatement, CBGStatementLine, CBGStatement.Type::"Bank/Giro", CBGStatementLine."Account Type"::Customer, CreateCustomer(), '');
        CBGStatementLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        CBGStatementLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";

        // Exercise.
        asserterror CBGStatementLine.Validate("VAT Type", CBGStatementLine."VAT Type"::" ");  // Blank VAT Type.

        // Verify: Verify error code, actual error is "You can only apply VAT when Account Type = G/L Account", CBG Statement Line table.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalculateVATWithFullVATTypeSaleError()
    var
        CBGStatementLine: Record "CBG Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Purpose of this test to Calculate VAT with VAT Calculation Type Full VAT for Sale in CBG Statement Line table.
        Initialize();
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT");
        VATOnCBGStatement(
          CBGStatementLine."Account Type"::"G/L Account", CreateGLAccount(), CBGStatementLine."VAT Type"::Sale,
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalculateVATWithFullVATTypePurchError()
    var
        CBGStatementLine: Record "CBG Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Purpose of this test to Calculate VAT with VAT Calculation Type Full VAT for Purchase in CBG Statement Line table.
        Initialize();
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT");
        VATOnCBGStatement(
          CBGStatementLine."Account Type"::"G/L Account", CreateGLAccount(), CBGStatementLine."VAT Type"::Purchase,
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure VATOnCBGStatement(AccountType: Option; AccountNo: Code[20]; VATType: Option; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Setup: Create CBG Statment.
        CreateCBGStatement(
          CBGStatement, CBGStatementLine, CBGStatement.Type::"Bank/Giro", AccountType, AccountNo, '');
        CBGStatementLine.Validate("VAT Type", VATType);
        CBGStatementLine.Validate("VAT Bus. Posting Group", VATBusPostingGroup);

        // Exercise.
        asserterror CBGStatementLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);

        // Verify: Verify error code, actual error is "When VAT Type = Sale  than Account No. ) must be equal to Sales VAT Account from the VAT Posting Setup table" and
        // When VAT Type = Purchase  than Account No. must be equal to Purchase VAT Account from the VAT Posting Setup table of CBG Statement Line table.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalculateVATWithFullVATSalesTaxError()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Purpose of this test validate Calculate VAT with VAT Calculation Type Sales tax in CBG Statement Table.
        Initialize();
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        CreateCBGStatement(
          CBGStatement, CBGStatementLine, CBGStatement.Type::"Bank/Giro",
          CBGStatementLine."Account Type"::"G/L Account", CreateGLAccount(), '');
        CBGStatementLine.Validate("VAT Type", CBGStatementLine."VAT Type"::Sale);
        CBGStatementLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        // Exercise.
        asserterror CBGStatementLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        // Verify: Verify error code, actual error is "VAT Calculation Type is not supported in the Cash, Bank or Giro Journal in VAT Posting Setup VAT Bus. Posting Group=,VAT Prod. Posting Group=" of CBG Statement Line table.
        Assert.ExpectedErrorCode('NCLCSRTS:TableErrorStr');
    end;

    [Test]
    procedure AccountNoTableRelationOnCBGStatementLine()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GLAccountNo: array[3] of Code[20];
        i: Integer;
        ExpectedErrorCodeLbl: Label 'DB:NothingInsideFilter', Locked = true;
    begin
        // [SCENARIO 495747] Account no. has table relation filters "Account Type" = Posting, Blocked = false and "Direct Posting" = true for type "G/L Account" on CBG statement line
        Initialize();

        // [GIVEN] Create three G/L accounts
        // [GIVEN] G/L account "A" has "Account Type" = "Begin Total"
        GLAccountNo[1] := CreateGLAccount("G/L Account Type"::"Begin-Total", false, true);
        // [GIVEN] G/L account "B" is blocked
        GLAccountNo[2] := CreateGLAccount("G/L Account Type"::Posting, true, true);
        // [GIVEN] G/L account "C" has not Direct Posting option
        GLAccountNo[3] := CreateGLAccount();

        //[WHEN] Validate "Account No." on the CBG Statement Line with these G/L accounts 
        for i := 1 to ArrayLen(GLAccountNo) do
            asserterror CBGStatementLine.Validate("Account No.", GLAccountNo[i]);

        //[THEN] The error "G/L Acount No. can't be found in G/L Account table" is executed
        Assert.ExpectedErrorCode(ExpectedErrorCodeLbl);
    end;

    local procedure Initialize()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT TAB Cash Bank Giro");
        LibraryVariableStorage.Clear();
        GenJournalTemplate.DeleteAll();
        GenJournalBatch.DeleteAll();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateBlockedCustomer(var Customer: Record Customer; Blocked: Enum "Customer Blocked"; PrivacyBlocked: Boolean)
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Blocked := Blocked;
        Customer."Privacy Blocked" := PrivacyBlocked;
        Customer.Insert();
    end;

    local procedure CreateBlockedVendor(var Vendor: Record Vendor; Blocked: Enum "Vendor Blocked"; PrivacyBlocked: Boolean)
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Blocked := Blocked;
        Vendor."Privacy Blocked" := PrivacyBlocked;
        Vendor.Insert();
    end;

    local procedure CreateCBGStatement(var CBGStatement: Record "CBG Statement"; var CBGStatementLine: Record "CBG Statement Line"; Type: Option; AccountType: Option; AccountNo: Code[20]; Currency: Code[10])
    begin
        CBGStatement."Journal Template Name" := CreateJournalTemplate(CreateGLAccount());
        CBGStatement."No." := LibraryRandom.RandInt(10);
        CBGStatement."Account No." := CBGStatement."Journal Template Name";
        CBGStatement.Date := WorkDate();
        CBGStatement.Type := Type;
        CBGStatement."Account Type" := CBGStatement."Account Type"::"G/L Account";
        CBGStatement."Opening Balance" := LibraryRandom.RandDec(100, 2);
        CBGStatement."Closing Balance" := CBGStatement."Opening Balance";
        CBGStatement.Currency := Currency;
        CBGStatement.Insert();

        CBGStatementLine."Journal Template Name" := CBGStatement."Journal Template Name";
        CBGStatementLine."No." := CBGStatement."No.";
        CBGStatementLine."Line No." := LibraryRandom.RandInt(10);
        CBGStatementLine."Account Type" := AccountType;
        CBGStatementLine."Account No." := AccountNo;
        CBGStatementLine.Date := CBGStatement.Date;
        CBGStatementLine."Statement Type" := CBGStatementLine."Statement Type"::"Bank Account";
        CBGStatementLine."Statement No." := CreateBankAccount();
        CBGStatementLine.Identification := LibraryUTUtility.GetNewCode();
        CBGStatementLine."Applies-to ID" := UserId;
        CBGStatementLine."Debit Incl. VAT" := LibraryRandom.RandDec(10, 2);
        CBGStatementLine."Credit Incl. VAT" := LibraryRandom.RandDec(10, 2);
        CBGStatementLine.Insert();
    end;

    local procedure CreateCBGStatementLine(var CBGStatementLine: Record "CBG Statement Line"; AccountType: Option; AccountNo: Code[20]; JournalTemplateName: Code[20]; No: Integer)
    begin
        CBGStatementLine."Journal Template Name" := JournalTemplateName;
        CBGStatementLine."No." := No;
        CBGStatementLine."Line No." := LibraryRandom.RandInt(10);
        CBGStatementLine."Account Type" := AccountType;
        CBGStatementLine.Validate("Account No.", AccountNo);
        CBGStatementLine.Validate("Applies-to ID", UserId);
        CBGStatementLine."Statement Type" := CBGStatementLine."Statement Type"::"Bank Account";
        CBGStatementLine."Statement No." := AccountNo;
        CBGStatementLine.Identification := LibraryUTUtility.GetNewCode();
        CBGStatementLine.Insert();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateCustomerLedgerEntry(): Code[20]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry2.FindLast();
        CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Customer No." := CreateCustomer();
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();
        exit(CustLedgerEntry."Customer No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Insert();
        exit(Currency.Code);
    end;

    local procedure CreateJournalTemplate(BalAccountNo: Code[20]): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate.Description := GenJournalTemplate.Name;
        GenJournalTemplate.Type := GenJournalTemplate.Type::Bank;
        GenJournalTemplate."Bal. Account Type" := GenJournalTemplate."Bal. Account Type"::"G/L Account";
        GenJournalTemplate."Bal. Account No." := BalAccountNo;
        GenJournalTemplate."No. Series" := CreateNoSeries();
        GenJournalTemplate."Source Code" := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate.Insert();
        exit(GenJournalTemplate.Name);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccount(GLAccountType: Enum Microsoft.Finance.GeneralLedger.Account."G/L Account Type"; Blocked: Boolean; DirectPosting: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount."Account Type" := GLAccountType;
        GLAccount.Blocked := Blocked;
        GLAccount."Direct Posting" := DirectPosting;
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.Code := LibraryUTUtility.GetNewCode10();
        NoSeries."Default Nos." := true;
        NoSeries.Insert();
        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine."Starting No." := LibraryUTUtility.GetNewCode();
        NoSeriesLine.Insert();
        exit(NoSeries.Code);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type")
    begin
        VATPostingSetup."VAT Bus. Posting Group" := CreateVATBusinessPostingGroup();
        VATPostingSetup."VAT Prod. Posting Group" := CreateVATProductPostingGroup();
        VATPostingSetup."VAT Calculation Type" := VATCalculationType;
        VATPostingSetup."VAT %" := LibraryRandom.RandInt(10);
        VATPostingSetup."Sales VAT Account" := CreateGLAccount();
        VATPostingSetup."Purchase VAT Account" := CreateGLAccount();
        VATPostingSetup.Insert();
    end;

    local procedure CreateVATBusinessPostingGroup(): Code[20]
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        VATBusinessPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        VATBusinessPostingGroup.Insert();
        exit(VATBusinessPostingGroup.Code);
    end;

    local procedure CreateVATProductPostingGroup(): Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        VATProductPostingGroup.Insert();
        exit(VATProductPostingGroup.Code);
    end;

    local procedure CreatePaymentHistory(OurBank: Code[20]; Identification: Code[80]; AccountNo: Code[20])
    var
        PaymentHistory: Record "Payment History";
        PaymentHistoryLine: Record "Payment History Line";
    begin
        PaymentHistory."Our Bank" := OurBank;
        PaymentHistory."Run No." := LibraryUTUtility.GetNewCode();
        PaymentHistory.Insert();

        PaymentHistoryLine."Our Bank" := PaymentHistory."Our Bank";
        PaymentHistoryLine."Run No." := PaymentHistory."Run No.";
        PaymentHistoryLine."Line No." := LibraryRandom.RandInt(10);
        PaymentHistoryLine.Identification := Identification;
        PaymentHistoryLine."Account Type" := PaymentHistoryLine."Account Type"::Customer;
        PaymentHistoryLine."Account No." := AccountNo;
        PaymentHistoryLine."Currency Code" := LibraryUTUtility.GetNewCode10();
        PaymentHistoryLine.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text; var Reply: Boolean)
    begin
        if (StrPos(Question, OpeningBalanceQst) > 0) or (StrPos(Question, PostingQst) > 0) then
            Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text; var Reply: Boolean)
    begin
        if (StrPos(Question, OpeningBalanceQst) > 0) or (StrPos(Question, PostingQst) > 0) then
            Reply := true;
    end;
}

