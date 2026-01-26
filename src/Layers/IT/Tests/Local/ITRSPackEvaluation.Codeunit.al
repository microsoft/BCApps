codeunit 148800 "IT RS Pack - Evaluation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyInfoBankAccountNo()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO 262564] Bank Account No. field of Company Information table has value which passes Italian format validation

        // [GIVEN] Fill in IBAN field of Company Information table with Italian format value
        CompanyInformation.Get();
        CompanyInformation.TestField("Bank Account No.");
        CompanyInformation.IBAN := 'IT24S1234522224222344322223';

        // [WHEN] Bank Account No. is being validated
        CompanyInformation.Validate("Bank Account No.");

        // [THEN] Validation passed without errors
        CompanyInformation.TestField("Bank Account No.");
    end;
}

