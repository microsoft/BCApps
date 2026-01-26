codeunit 144543 "ERM Cash Management"
{
    // 1.Verify Account Number With TeleBank Description Out of Range in Local Functionality Management.
    // 2.Verify Account Number With TeleBank Description Within Range in Local Functionality Management.
    // 
    // Covers Test Cases for Bug Id: 6692
    //  ---------------------------------------------------------------------------------------------
    //  Test Function Name                                                                 TFS ID
    //  ---------------------------------------------------------------------------------------------
    // VerifyAccountNoOutOfRange, VerifyAccountNoWithinRange

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        TeleBankDescOutofRangeTxt: Label 'MEI 12APRIL 13, SP 888298+';
        TeleBankDescWithinRangeTxt: Label 'MEI 12MAY 13, SP 888298+';
        TelebankDescErr: Label '%1 must be %2 .';
        ExpectedDescWithinRangeTxt: Label '11213888298';

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAccountNoOutOfRange()
    var
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        CountryCode: Code[10];
        AccountNo: Text[30];
        IsAccountNo: Boolean;
    begin
        // Verify Account Number With TeleBank Description Within Range in Local Functionality Management.

        // Setup & Exercise.
        CountryCode := '';
        IsAccountNo := LocalFunctionalityMgt.CheckBankAccNo(TeleBankDescOutofRangeTxt, CountryCode, AccountNo);

        // Verify.
        VerifyAccountNo(AccountNo, TeleBankDescOutofRangeTxt, IsAccountNo, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAccountNoWithinRange()
    var
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        CountryCode: Code[10];
        AccountNo: Text[30];
        IsAccountNo: Boolean;
    begin
        // Verify Account Number With TeleBank Description Out of Range in Local Functionality Management.

        // Setup & Exercise.
        CountryCode := '';
        IsAccountNo := LocalFunctionalityMgt.CheckBankAccNo(TeleBankDescWithinRangeTxt, CountryCode, AccountNo);

        // Verify.
        VerifyAccountNo(AccountNo, ExpectedDescWithinRangeTxt, IsAccountNo, true);
    end;

    local procedure VerifyAccountNo(AccountNo: Text; ExpectedDesc: Text; IsAccountNoActual: Boolean; IsAccountNoExpected: Boolean)
    begin
        if not (AccountNo = ExpectedDesc) and (IsAccountNoActual = IsAccountNoExpected) then
            Error(TelebankDescErr, AccountNo, ExpectedDesc);
    end;
}

