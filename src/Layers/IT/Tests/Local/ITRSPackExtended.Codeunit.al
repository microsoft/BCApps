codeunit 148600 "IT RS Pack - Extended"
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
        IsDemoCompany: Boolean;
    begin
        // [SCENARIO 262564] Bank Account No. field of Company Information table has value which passes Italian format validation

        // [GIVEN] Fill in IBAN field of Company Information table with Italian format value
        CompanyInformation.Get();
        if CompanyInformation.Name = '' then
            IsDemoCompany := false
        else
            IsDemoCompany := CompanyInformation.Name.Contains('CRONUS');

        if IsDemoCompany then
            CompanyInformation.TestField("Bank Account No.");

        CompanyInformation.IBAN := 'IT24S1234522224222344322223';

        // [WHEN] Bank Account No. is being validated
        CompanyInformation.Validate("Bank Account No.");

        // [THEN] Validation passed without errors
        CompanyInformation.TestField("Bank Account No.");
    end;
}

