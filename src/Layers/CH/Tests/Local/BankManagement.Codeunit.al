codeunit 144042 "Bank Management"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        BankMgt: Codeunit BankMgt;
        Assert: Codeunit Assert;
        PostAccDashExpectedErr: Label 'Post account numbers must have a dash on the 3rd and the 2nd last position. i.e. 60-8000-7 or 01-20029-2.';
        PostAccToFewDigitExpectedErr: Label 'The post account number must have at least 6 digits.';
        PostAccWrongCheckDigitExpectedErr: Label 'The check digit of post account 30-54703-1 must be 2.';
        PostAccOnlyDigitsExpectedErr: Label 'The check digit for 30054A03 cannot be calculated. The source number may only consist of digits.';
        PostAccNotValidErr: Label 'Returned Post Account is not valid.';

    [Test]
    [Scope('OnPrem')]
    procedure CheckPostAccountValidValueTest()
    var
        BankAccNo: Code[20];
    begin
        // Positive test. Expect return value to be same as input value.
        BankAccNo := BankMgt.CheckPostAccountNo('30-54703-2');
        Assert.AreEqual(BankAccNo, '30-054703-2', PostAccNotValidErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPostAccountValidEmptyValueTest()
    var
        BankAccNo: Code[20];
    begin
        // Positive test. Expect return value to be same as input value.
        BankAccNo := BankMgt.CheckPostAccountNo('');
        Assert.AreEqual(BankAccNo, '', PostAccNotValidErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPostAccountDashNeededErrorTest()
    begin
        // Error test. Account No need dashes ..
        asserterror BankMgt.CheckPostAccountNo('300500047032');
        Assert.ExpectedError(PostAccDashExpectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPostAccountToFewCharsErrorTest()
    begin
        // Error test. Account No need as minimum 6 chars ..
        asserterror BankMgt.CheckPostAccountNo('30-2');
        Assert.ExpectedError(PostAccToFewDigitExpectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPostAccountWrongCheckDigitErrorTest()
    begin
        // Error test. The last Check Digit (1) is wrong ..
        asserterror BankMgt.CheckPostAccountNo('30-54703-1');
        Assert.ExpectedError(PostAccWrongCheckDigitExpectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPostAccountOnlyDigitAllowedErrorTest()
    begin
        // Error test. Only digits is allowed in Post Account No ..
        asserterror BankMgt.CheckPostAccountNo('30-54A03-2');
        Assert.ExpectedError(PostAccOnlyDigitsExpectedErr);
    end;
}

