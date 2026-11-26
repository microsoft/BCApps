codeunit 144011 "UT COMPANY"
{
    // Includes Company UT:
    // 
    //  1. Test to verify that Registered Post Code field exist on the Company Information Page.
    //  2. Test to verify that Post Code field exist on the Company Information Page.
    //  3. Test to verify that Registered City field exist on the Company Information Page.
    //  4. Test to verify that Registered Name field exist on the Company Information Page.
    //  5. Test to verify that Registration No. field exist on the Company Information Page.
    //  6. Test to verify that County field exist on the Company Information Page.
    //  7. Test to verify that Registered Address field exist on the Company Information Page.
    //  8. Test to verify that Registered Address 2 field exist on the Company Information Page.
    //  9. Test to verify that Registered County field exist on the Company Information Page.
    // 11. Test to verify that Registered Post Code field is populated correctly when validate the Registered City on Company Information.
    // 12. Test to verify that Registered City field is populated correctly when validate the Registered Post Code on Company Information.
    // 
    //   Covers Test cases: 340161
    //   ----------------------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                                      TFS ID
    //   ----------------------------------------------------------------------------------------------------------------
    //   RegisteredPostCodeExistOnCompanyInformationPage, PostCodeExistOnCompanyInformationPage                  159615
    //   RegisteredCityExistOnCompanyInformationPage, RegisteredNameExistOnCompanyInformationPage                159615
    //   RegistrationNoExistOnCompanyInformationPage, CountyExistOnCompanyInformationPage                        159615
    //   RegisteredAddressExistOnCompanyInformationPage, RegisteredAddress2ExistOnCompanyInformationPage         159615
    //   RegisteredCountyExistOnCompanyInformationPage, BranchNumberExistOnCompanyInformationPage                159615
    //   OnValidateRegisteredCityCompanyInformationTable                                                         159616
    //   OnValidateRegisteredPostCodeCompanyInformationTable                                                     159617

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PostCodeExistOnCompanyInformationPage()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of the test is to validate that Post Code field exist on the Company Information Page.
        CheckControlOnCompanyInformationPage(CompanyInformation.FieldNo("Post Code"));
    end;


    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RegistrationNoExistOnCompanyInformationPage()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of the test is to validate that Registration No. field exist on the Company Information Page.
        CheckControlOnCompanyInformationPage(CompanyInformation.FieldNo("Registration No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CountyExistOnCompanyInformationPage()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of the test is to validate that County field exist on the Company Information Page.
        CheckControlOnCompanyInformationPage(CompanyInformation.FieldNo(County));
    end;


    local procedure CheckControlOnCompanyInformationPage(FieldNo: Integer)
    var
        ControlExist: Boolean;
    begin
        // Setup and Exercise: Find Control on Company Information Page with Field No.
        ControlExist := LibraryUtilityOnPrem.FindControl(1, FieldNo);  // 1 used for Company Information Page Id.

        // Verify: Verify that control exist on Company Information page.
        Assert.AreEqual(true, ControlExist, 'Control must exist');
    end;

}

