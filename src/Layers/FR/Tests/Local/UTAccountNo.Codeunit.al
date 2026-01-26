codeunit 144003 "UT Account No"
{
    // 1. Purpose of the test is to validate On Validate - No. error on G/L Account No. Field on Table ID 15 G/L Account.
    // 2. Purpose of the test is to validate On Validate - No. Income/Balance Balance Sheet on G/L Account No. Field on Table ID 15 G/L Account.
    // 3. Purpose of the test is to validate On Validate - No. Income/Balance Income Statement on G/L Account No. Field on Table ID 15 G/L Account.
    // 
    // Covers Test Cases for WI - 344647.
    // -----------------------------------------------------------------------
    // Test Function Name                                       TFS ID
    // -----------------------------------------------------------------------
    // OnValidateNoGLAccountError                               151066,151079
    // OnValidateNoGLAccountBalanceSheet                        151076,206269
    // OnValidateNoGLAccountIncomeStatement                     151077,151078

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateNoGLAccountError()
    var
        GLAccount: Record "G/L Account";
    begin
        // Purpose of the test is to validate On Validate - No. error on G/L Account No. Field on Table ID 15 G/L Account.

        // Exercise.
        asserterror GLAccount.Validate("No.", CopyStr(CreateGuid(), 1, 20));  // Since No. field length is 20.

        // Verify: Verify actual error message The first number in No. must be from 1 to 9.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateNoGLAccountBalanceSheet()
    var
        GLAccount: Record "G/L Account";
    begin
        // Purpose of the test is to validate On Validate - No. Income/Balance Balance Sheet on G/L Account No. Field on Table ID 15 G/L Account.

        // Using Random for GL Account No.,taking first Character of G/L Account 1 to 5 for Income/Balance as Balance Sheet.
        OnValidateNoGLAccount(Format(LibraryRandom.RandIntInRange(1, 5)), GLAccount."Income/Balance"::"Balance Sheet");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateNoGLAccountIncomeStatement()
    var
        GLAccount: Record "G/L Account";
    begin
        // Purpose of the test is to validate On Validate - No. Income/Balance Income Statement on G/L Account No. Field on Table ID 15 G/L Account.

        // Using Random for GL Account No.,taking first character of G/L Account 6 to 9 for Income/Balance as Income Statement.
        OnValidateNoGLAccount(Format(LibraryRandom.RandIntInRange(6, 9)), GLAccount."Income/Balance"::"Income Statement");
    end;

    local procedure OnValidateNoGLAccount(GLAccountNo: Code[20]; IncomeBalance: Enum "G/L Account Report Type")
    var
        GLAccount: Record "G/L Account";
    begin
        // Exercise.
        GLAccount.Validate("No.", GLAccountNo);

        // Verify.
        GLAccount.TestField("Income/Balance", IncomeBalance);
    end;
}

