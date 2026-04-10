codeunit 134113 "ERM Test Employee Expense"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Employee Expenses]
    end;

    var
        DummyGenJournalLine: Record "Gen. Journal Line";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        TypeMistmatchErr: Label '%1 or %2 must be a G/L Account or Bank Account.', Comment = '%1=Account Type,%2=Balance Account Type';

    [Scope('OnPrem')]
    procedure Initialize()
    var
        Employee: Record Employee;
        EmployeePostingGroup: Record "Employee Posting Group";
        EmployeePostingGroupCode: Code[20];
    begin
        Employee.DeleteAll();
        EmployeePostingGroup.DeleteAll();

        EmployeePostingGroupCode := CreateEmployeePostingGroup(LibraryERM.CreateGLAccountNoWithDirectPosting());
        CreateEmployeeWithExpensePostingGroup(EmployeePostingGroupCode);
    end;

    local procedure CreateEmployeePostingGroup(ExpenseAccNo: Code[20]): Code[20]
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        EmployeePostingGroup.Init();
        EmployeePostingGroup.Validate(Code, LibraryUtility.GenerateGUID());
        EmployeePostingGroup.Validate("Payables Account", ExpenseAccNo);
        EmployeePostingGroup.Insert(true);
        exit(EmployeePostingGroup.Code);
    end;

    local procedure CreateEmployeeWithExpensePostingGroup(EmployeePostingGroupCode: Code[20])
    var
        Employee: Record Employee;
    begin
        Employee.Validate("No.", LibraryUtility.GenerateGUID());
        Employee.Validate("First Name", LibraryUtility.GenerateRandomAlphabeticText(10, 0));
        Employee.Validate("Last Name", LibraryUtility.GenerateRandomAlphabeticText(10, 0));
        Employee.Validate("Employee Posting Group", EmployeePostingGroupCode);
        Employee.Insert(true);
    end;

    local procedure CreateBalanceSheetAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate(Blocked, false);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; NoOfLine: Integer; GLAccountNo: Code[20]; EmployeeNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Counter: Integer;
    begin
        SelectGenJournalBatch(GenJournalBatch);
        for Counter := 1 to NoOfLine do
            LibraryERM.CreateGeneralJnlLineWithBalAcc(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::"G/L Account", GLAccountNo, GenJournalLine."Bal. Account Type"::Employee, EmployeeNo, Amount);
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateGenJnlDescriptionForEmp()
    var
        Employee: Record Employee;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // [GIVEN] An employee
        Employee.FindFirst();

        // [WHEN] The user assigns account No on General journal to this employee
        CreateGeneralJournalLine(GenJournalLine, 1, '', Employee."No.", LibraryRandom.RandDecInRange(1, 100, 2));

        // [THEN] The description on the line should be updated to the employee Full name
        Assert.AreEqual(Employee.FullName(), GenJournalLine.Description, 'Error Employee Name should be in the description');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateGenJnlDescriptionForLongEmpName()
    var
        Employee: Record Employee;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // [GIVEN] An employee with long name more than 50 character
        Employee.FindFirst();
        Employee.Validate("First Name", LibraryUtility.GenerateRandomAlphabeticText(30, 0));
        Employee.Validate("Middle Name", LibraryUtility.GenerateRandomAlphabeticText(30, 0));
        Employee.Validate("Last Name", LibraryUtility.GenerateRandomAlphabeticText(30, 0));
        Employee.Modify(true);

        // [WHEN] The user assigns account No on General journal to this employee
        CreateGeneralJournalLine(GenJournalLine, 1, '', Employee."No.", LibraryRandom.RandDecInRange(1, 100, 2));

        // [THEN] The description on the line should be updated to the employee initials
        Assert.AreEqual(Employee.FullName(), GenJournalLine.Description, 'Error Employee Name should be in the description');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotTransferFromVendToEmp()
    var
        Employee: Record Employee;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // [GIVEN] An employee
        Employee.FindFirst();

        // [WHEN] The user assigns account type to employee , and sets bal account type to vendor
        CreateGeneralJournalLine(GenJournalLine, 1, '', Employee."No.", LibraryRandom.RandDecInRange(1, 100, 2));
        asserterror GenJournalLine.Validate("Account Type", DummyGenJournalLine."Bal. Account Type"::Vendor);

        // [THEN] user should get an error that this isn't allowed
        Assert.ExpectedError(
          StrSubstNo(TypeMistmatchErr, GenJournalLine.FieldCaption("Account Type"), GenJournalLine.FieldCaption("Bal. Account Type")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingDescriptionFromAccount()
    var
        Employee: Record Employee;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize();
        // [GIVEN] An employee
        Employee.FindFirst();

        // [WHEN] The user assigns account type to G/L account and leaves account No to empty and sets Bal account No to Employee No
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          DummyGenJournalLine."Bal. Account Type"::Employee, Employee."No.", GenJournalLine."Account Type"::"G/L Account", '',
          LibraryRandom.RandDecInDecimalRange(1, 100, 2));

        // [THEN] The description on the line should be updated to the employee Full name
        Assert.AreEqual(Employee.FullName(), GenJournalLine.Description, 'Error Employee Name should be in the description');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingEmpExpenseFromGenJnl()
    var
        Employee: Record Employee;
        GLEntry: Record "G/L Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        ExpenseAccNo: Code[20];
        Amount: Decimal;
    begin
        Initialize();

        // [GIVEN] An employee and expense balance sheet G/L account
        ExpenseAccNo := CreateBalanceSheetAccount();
        Employee.FindFirst();
        Amount := LibraryRandom.RandDecInRange(1, 100, 2);

        // [WHEN] The user assigns account No on General journal to this employee and balance to the expense account and post
        CreateGeneralJournalLine(GenJournalLine, 1, ExpenseAccNo, Employee."No.", Amount);
        GenJournalLine.TestField("Source Code");

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GLEntry.SetRange("G/L Account No.", ExpenseAccNo);
        GLEntry.FindFirst();
        Assert.AreEqual(1, GLEntry.Count, 'Error Multiple G/L entries were created when posting Gen. Journal Line');
        Assert.AreEqual(
          DummyGenJournalLine."Bal. Account Type"::Employee, GLEntry."Bal. Account Type",
          'Error Bal. Account type is not set to employee');
        Assert.AreEqual(Employee."No.", GLEntry."Bal. Account No.", 'Error Bal. Account No. is not set to employee No.');

        EmployeeLedgerEntry.SetRange("Employee No.", Employee."No.");
        EmployeeLedgerEntry.FindFirst();
        EmployeeLedgerEntry.CalcFields("Amount (LCY)");
        EmployeeLedgerEntry.TestField("Source Code");
        Assert.AreEqual(
          1, EmployeeLedgerEntry.Count, 'Error Multiple employee ledger entries were created when posting Gen. Journal Line');
        Assert.AreEqual(
          DummyGenJournalLine."Bal. Account Type"::"G/L Account", EmployeeLedgerEntry."Bal. Account Type",
          'Error Bal. Account type is not set to G/L Account');
        Assert.AreEqual(ExpenseAccNo, EmployeeLedgerEntry."Bal. Account No.", 'Error Bal. Account No. is not set to G/L Account No.');
        Assert.AreNotEqual('', EmployeeLedgerEntry."Employee Posting Group", 'Error Employee Posting Group is empty');
        Assert.AreEqual(-Amount, EmployeeLedgerEntry."Amount (LCY)", 'Error Amount is not equal to amount set on General Journal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingEmpExpenseFromGenJnlWithNoBalAcc()
    var
        Employee: Record Employee;
        EmployeeGLEntry: Record "G/L Entry";
        ExpenseAccGLEntry: Record "G/L Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseAccNo: Code[20];
        FirstAmount: Decimal;
        SecondAmount: Decimal;
        BalancingAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] An employee and expense balance sheet G/L account
        ExpenseAccNo := CreateBalanceSheetAccount();
        Employee.FindFirst();
        FirstAmount := LibraryRandom.RandDecInRange(1, 100, 2);
        SecondAmount := LibraryRandom.RandDecInRange(1, 100, 2);
        BalancingAmount := -(FirstAmount + SecondAmount);

        // [WHEN] The user assigns account No on General journal to this employee and balance to the expense account and post
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", ExpenseAccNo, FirstAmount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", ExpenseAccNo, SecondAmount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Employee, Employee."No.", BalancingAmount);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        ExpenseAccGLEntry.SetRange("G/L Account No.", ExpenseAccNo);
        ExpenseAccGLEntry.FindSet();
        Assert.AreEqual(2, ExpenseAccGLEntry.Count, 'Error Multiple G/L entries were created when posting Gen. Journal Line');
        Assert.AreEqual(FirstAmount, ExpenseAccGLEntry.Amount, 'Error amount incorrect on first Expense Account GL Entry');
        ExpenseAccGLEntry.Next();
        Assert.AreEqual(SecondAmount, ExpenseAccGLEntry.Amount, 'Error amount incorrect on second Expense Account GL Entry');

        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        EmployeeGLEntry.SetRange("G/L Account No.", EmployeePostingGroup.GetPayablesAccount());
        EmployeeGLEntry.FindFirst();
        Assert.AreEqual(1, EmployeeGLEntry.Count, 'Error Multiple Employee G/L entries were created when posting Gen. Journal Line');
        Assert.AreEqual(BalancingAmount, EmployeeGLEntry.Amount, 'Error amount incorrect on Employee GL Entry');

        EmployeeLedgerEntry.SetRange("Employee No.", Employee."No.");
        EmployeeLedgerEntry.FindFirst();
        EmployeeLedgerEntry.CalcFields("Amount (LCY)");
        Assert.AreEqual(
          1, EmployeeLedgerEntry.Count, 'Error Multiple employee ledger entries were created when posting Gen. Journal Line');
        Assert.AreNotEqual('', EmployeeLedgerEntry."Employee Posting Group", 'Error Employee Posting Group is empty');
        Assert.AreEqual(BalancingAmount, EmployeeLedgerEntry."Amount (LCY)", 'Error Amount is not equal to amount set on General Journal');
    end;
}

