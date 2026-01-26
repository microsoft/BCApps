codeunit 142065 "UT TAB VATSTAT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TaxOfficeCityOnValidateCompanyInformation()
    var
        PostCode: Record "Post Code";
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of the test is to validate Trigger OnValidate of Tax Office City for Table 79 - Company Information.
        // Setup.
        CreatePostCode(PostCode);
        CreateCompanyInformation(CompanyInformation);

        // Exercise.
        CompanyInformation.Validate("Tax Office City", PostCode.City);

        // Verify.
        CompanyInformation.TestField("Tax Office Post Code", PostCode.Code);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TaxOfficePostCodeOnValidateCompanyInformation()
    var
        PostCode: Record "Post Code";
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of the test is to validate Trigger OnValidate of Tax Office Post Code for Table 79 - Company Information.
        // Setup.
        CreatePostCode(PostCode);
        CreateCompanyInformation(CompanyInformation);

        // Exercise.
        CompanyInformation.Validate("Tax Office Post Code", PostCode.Code);

        // Verify.
        CompanyInformation.TestField("Tax Office City", PostCode.City);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PageIDOnValidateVATStatementTemplate()
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        // Purpose of the test is to validate Trigger OnValidate of Page ID for Table 255 - VAT Statement Template.

        // Setup: Create VAT Statement Template.
        VATStatementTemplate.Name := LibraryUTUtility.GetNewCode10();
        VATStatementTemplate.Insert();

        // Exercise.
        VATStatementTemplate.Validate("Page ID");

        // Verify.
        VATStatementTemplate.TestField("VAT Statement Report ID");
    end;

    local procedure CreatePostCode(var PostCode: Record "Post Code")
    begin
        PostCode.Code := LibraryUTUtility.GetNewCode();
        PostCode.City := 'City';
        PostCode."Search City" := PostCode.City;
        PostCode.Insert();
    end;

    local procedure CreateCompanyInformation(var CompanyInformation: Record "Company Information")
    begin
        CompanyInformation."Primary Key" := LibraryUTUtility.GetNewCode10();
        CompanyInformation.Insert();
    end;
}

