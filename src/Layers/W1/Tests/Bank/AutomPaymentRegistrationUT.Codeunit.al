codeunit 134712 "Autom. Payment Registration.UT"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Reconciliation]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LineNoTAppliedErr: Label 'The line with transaction date %1 and transaction text ''%2'' is not applied. You must apply all lines.', Comment = '%1 - transaction date, %2 - arbitrary text';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure t273_BankAccountNo_ValidateFor_TypeBankReconciliation()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccNo: Code[20];
    begin
        Initialize();

        BankAccNo := CreateBankAcc();

        BankAccReconciliation.Init();
        BankAccReconciliation.Validate("Bank Account No.", BankAccNo);
        BankAccReconciliation.Insert(true);

        ValidateLastStmntsNos(BankAccNo, '1', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure t273_BankAccountNo_ValidateFor_TypeBankReconciliation_LastStmntNoIsExists()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccNo: Code[20];
    begin
        Initialize();

        BankAccNo := CreateBankAcc();

        BankAccount.Get(BankAccNo);
        BankAccount."Last Statement No." := '0';
        BankAccount.Modify();

        BankAccReconciliation.Init();
        BankAccReconciliation.Validate("Bank Account No.", BankAccNo);
        BankAccReconciliation.Insert(true);

        ValidateLastStmntsNos(BankAccNo, '1', '');
        Assert.AreEqual('1', BankAccReconciliation."Statement No.", 'Wrong "Statement No." on BankAccReconciliation.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure t273_BankAccountNo_ValidateFor_TypePaymentApplication()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccNo: Code[20];
    begin
        Initialize();

        BankAccNo := CreateBankAcc();

        BankAccReconciliation.Init();
        BankAccReconciliation."Statement Type" := BankAccReconciliation."Statement Type"::"Payment Application";
        BankAccReconciliation.Validate("Bank Account No.", BankAccNo);
        BankAccReconciliation.Insert(true);

        ValidateLastStmntsNos(BankAccNo, '', '1');
        Assert.AreEqual('1', BankAccReconciliation."Statement No.", 'Wrong "Statement No." on BankAccReconciliation.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure t237_CreateNewBankPaymentAppBatch()
    var
        BankAccReconciliationCaller: Record "Bank Acc. Reconciliation";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccNo: Code[20];
    begin
        Initialize();

        BankAccNo := CreateBankAcc();
        BankAccReconciliationCaller.CreateNewBankPaymentAppBatch(BankAccNo, BankAccReconciliation);

        ValidateLastStmntsNos(BankAccNo, '', '1');
        Assert.AreEqual(
          BankAccReconciliation."Statement Type"::"Payment Application", BankAccReconciliation."Statement Type",
          '2. Wrong "Statement Type" on Bank Acc Reconciliation.');
        Assert.AreEqual(BankAccNo, BankAccReconciliation."Bank Account No.", '3. Wrong "Bank Account No." on Bank Acc Reconciliation.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure t237_CreateNewBankPaymentAppBatch_WrongBancAcc()
    var
        BankAccReconciliationCaller: Record "Bank Acc. Reconciliation";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccNo: Code[20];
    begin
        Initialize();

        BankAccNo := CopyStr(CreateGuid(), 1, 20);
        asserterror
          BankAccReconciliationCaller.CreateNewBankPaymentAppBatch(BankAccNo, BankAccReconciliation);

        Assert.ExpectedError(BankAccNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure t273_SetFiltersOnBankAccReconLineTable()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TestStatementNo: Code[20];
    begin
        Initialize();

        InsertDummyBankReconHeaderAndLine("Bank Acc. Rec. Stmt. Type"::"Bank Reconciliation", '0', BankAccReconciliation);
        InsertDummyBankReconHeaderAndLine("Bank Acc. Rec. Stmt. Type"::"Payment Application", '0', BankAccReconciliation);
        TestStatementNo := 'TEST1';
        InsertDummyBankReconHeaderAndLine("Bank Acc. Rec. Stmt. Type"::"Payment Application", TestStatementNo, BankAccReconciliation);

        BankAccReconciliation.SetFiltersOnBankAccReconLineTable(
          BankAccReconciliation, BankAccReconciliationLine);

        BankAccReconciliationLine.FindFirst();

        Assert.AreEqual(
          1, BankAccReconciliationLine.Count, '1.Wrong filtering on BankAccReconciliationLine table.');

        Assert.AreEqual(
          TestStatementNo, BankAccReconciliationLine."Statement No.", '2.Wrong filtering on BankAccReconciliationLine table.');
    end;

    [Test]
    [HandlerFunctions('UIConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure Post_YesNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        Initialize();

        InsertDummyBankReconHeaderAndLine("Bank Acc. Rec. Stmt. Type"::"Payment Application", '0', BankAccReconciliation);
        BankAccReconciliation.SetFiltersOnBankAccReconLineTable(
          BankAccReconciliation, BankAccReconciliationLine);

        BankAccReconciliationLine.FindFirst();
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");

        asserterror CODEUNIT.Run(CODEUNIT::"Bank Acc. Recon. Post (Yes/No)", BankAccReconciliation);
        Assert.ExpectedError(
          StrSubstNo(LineNoTAppliedErr, BankAccReconciliationLine."Transaction Date", BankAccReconciliationLine."Transaction Text"));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Autom. Payment Registration.UT");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
    end;

    local procedure InsertDummyBankReconHeaderAndLine(StatementType: Enum "Bank Acc. Rec. Stmt. Type"; StatementNo: Code[20]; var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliation.Init();
        BankAccReconciliation."Statement Type" := StatementType;
        BankAccReconciliation."Bank Account No." := CreateBankAcc();
        BankAccReconciliation."Statement No." := StatementNo;
        BankAccReconciliation.Insert();

        BankAccReconciliationLine.Init();
        BankAccReconciliationLine."Statement Type" := StatementType;
        BankAccReconciliationLine."Bank Account No." := BankAccReconciliation."Bank Account No.";
        BankAccReconciliationLine."Statement No." := StatementNo;
        BankAccReconciliationLine."Statement Amount" := 1;
        BankAccReconciliationLine.Insert();
    end;

    local procedure CreateBankAcc(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Init();
        BankAccount."No." := CopyStr(CreateGuid(), 1, 20);
        BankAccount.Insert();

        exit(BankAccount."No.");
    end;

    local procedure ValidateLastStmntsNos(BankAccNo: Code[20]; ExpLastStatementNo: Code[20]; ExpLastPaymentStatementNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccNo);

        Assert.AreEqual(ExpLastStatementNo, BankAccount."Last Statement No.", 'Wrong Last Statement No.');
        Assert.AreEqual(ExpLastPaymentStatementNo, BankAccount."Last Payment Statement No.", 'Wrong Last Payment Statement No.');
    end;

    local procedure UpdateBankAccRecStmEndingBalance(var BankAccRecon: Record "Bank Acc. Reconciliation"; NewStmEndingBalance: Decimal)
    begin
        BankAccRecon.Validate("Statement Ending Balance", NewStmEndingBalance);
        BankAccRecon.Modify();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UIConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndReconcilePageHandler(var PostPmtsAndRecBankAcc: TestPage "Post Pmts and Rec. Bank Acc.")
    begin
        PostPmtsAndRecBankAcc.OK().Invoke();
    end;
}

