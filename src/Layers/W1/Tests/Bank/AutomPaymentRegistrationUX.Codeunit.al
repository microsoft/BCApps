codeunit 134711 "Autom. Payment Registration.UX"
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
        TransactionAmountMustNotBeZeroErr: Label 'The Transaction Amount field must have a value that is not 0.';
        LineNoTAppliedErr: Label 'The line with transaction date %1 and transaction text ''%2'' is not applied. You must apply all lines.', Comment = '%1 - transaction date, %2 - arbitrary text';

    [Test]
    [HandlerFunctions('UIConfirmHandler,ModalBasicBankAccountCardHandler')]
    [Scope('OnPrem')]
    procedure ImportNewStatementToNonSetBankAcc()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccNo: Code[20];
    begin
        Initialize();

        BankAccNo := CreateBankAcc();
        BankAccReconciliation.Init();
        BankAccReconciliation."Statement Type" := BankAccReconciliation."Statement Type"::"Payment Application";
        BankAccReconciliation."Bank Account No." := BankAccNo;

        BankAccReconciliation.ImportBankStatement();
    end;

    [Test]
    [HandlerFunctions('UIMessageHandler,ModalBasicBankAccountListHandler')]
    [Scope('OnPrem')]
    procedure ImportNewStatement_NoBankAcc()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        Initialize();

        DeleteAllBankAcc();

        BankAccReconciliation.OpenNewWorksheet();

        // Validation for this case in HandlerFunctions
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportNewStatement_Only1BankAcc_WithoutFileFormat()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankPaymentWorksheet: TestPage "Payment Reconciliation Journal";
    begin
        Initialize();

        DeleteAllBankAcc();
        CreateBankAcc();

        BankPaymentWorksheet.Trap();
        BankAccReconciliation.OpenNewWorksheet();

        BankPaymentWorksheet.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportNewStatement_StmntNo()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankPaymentWorksheet: TestPage "Payment Reconciliation Journal";
        BankAccNo: Code[20];
    begin
        Initialize();

        DeleteAllBankAcc();
        BankAccNo := CreateBankAcc();

        BankPaymentWorksheet.Trap();
        BankAccReconciliation.OpenNewWorksheet();
        BankPaymentWorksheet.Close();

        BankAccount.Get(BankAccNo);
        BankAccReconciliation.SetRange("Bank Account No.", BankAccNo);
        BankAccReconciliation.FindFirst();

        Assert.AreNotEqual('', BankAccount."Last Payment Statement No.", '1. Wrong "Last Payment Statement No." on Bank Account table.');
        Assert.AreEqual(
          BankAccReconciliation."Statement No.", BankAccount."Last Payment Statement No.",
          '2. Wrong Statement No on Bank Payment Application page.');
        Assert.AreEqual(
          '', BankAccount."Last Statement No.", '3. Wrong Last Statement No on Bank Account table.');
    end;

    [Test]
    [HandlerFunctions('UIConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure Post_YesNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankPaymentApplication: TestPage "Payment Reconciliation Journal";
    begin
        Initialize();

        InsertDummyBankReconHeaderAndLine("Bank Acc. Rec. Stmt. Type"::"Payment Application", '0', BankAccReconciliation, 1);

        BankAccReconciliation.SetFiltersOnBankAccReconLineTable(
          BankAccReconciliation, BankAccReconciliationLine);
        BankAccReconciliationLine.FindFirst();

        BankPaymentApplication.OpenEdit();
        BankPaymentApplication.GotoRecord(BankAccReconciliationLine);
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation, BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        asserterror BankPaymentApplication.Post.Invoke();
        Assert.ExpectedError(
          StrSubstNo(LineNoTAppliedErr, BankAccReconciliationLine."Transaction Date", BankAccReconciliationLine."Transaction Text"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StatementAmountMustNotBeZero()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankPaymentApplication: TestPage "Payment Reconciliation Journal";
    begin
        Initialize();

        InsertDummyBankReconHeaderAndLine("Bank Acc. Rec. Stmt. Type"::"Payment Application", '0', BankAccReconciliation, 0);

        BankAccReconciliation.SetFiltersOnBankAccReconLineTable(
          BankAccReconciliation, BankAccReconciliationLine);
        BankAccReconciliationLine.FindFirst();

        BankPaymentApplication.OpenEdit();
        BankPaymentApplication.GotoRecord(BankAccReconciliationLine);
        asserterror BankPaymentApplication.ApplyEntries.Invoke();
        Assert.ExpectedError(TransactionAmountMustNotBeZeroErr);
    end;

    local procedure Initialize()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Autom. Payment Registration.UX");
        LibraryVariableStorage.Clear();
        BankAccReconciliation.DeleteAll(true);
    end;

    local procedure InsertDummyBankReconHeaderAndLine(StatementType: Enum "Bank Acc. Rec. Stmt. Type"; StatementNo: Code[20]; var BankAccReconciliation: Record "Bank Acc. Reconciliation"; StatementAmount: Decimal)
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
        BankAccReconciliationLine."Statement Amount" := StatementAmount;
        BankAccReconciliationLine.Insert();
    end;

    local procedure DeleteAllBankAcc()
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.DeleteAll();
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

    [MessageHandler]
    [Scope('OnPrem')]
    procedure UIMessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalBasicBankAccountListHandler(var BasicBankAccountList: TestPage "Payment Bank Account List")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalBasicBankAccountCardHandler(var BasicBankAccountCard: TestPage "Bank Account Card")
    begin
        BasicBankAccountCard.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndReconcilePageHandler(var PostPmtsAndRecBankAcc: TestPage "Post Pmts and Rec. Bank Acc.")
    begin
        PostPmtsAndRecBankAcc.OK().Invoke();
    end;
}

