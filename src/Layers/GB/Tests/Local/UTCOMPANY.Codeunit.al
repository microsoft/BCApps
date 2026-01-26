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
#if not CLEAN27
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RegisteredPostCodeExistOnCompanyInformationPage()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of the test is to validate that Registered Post Code field exist on the Company Information Page.
        CheckControlOnCompanyInformationPage(CompanyInformation.FieldNo("Registered Post Code"));
    end;
#endif

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

#if not CLEAN27
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RegisteredCityExistOnCompanyInformationPage()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of the test is to validate that Registered City field exist on the Company Information Page.
        CheckControlOnCompanyInformationPage(CompanyInformation.FieldNo("Registered City"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RegisteredNameExistOnCompanyInformationPage()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of the test is to validate that Registered Name field exist on the Company Information Page.
        CheckControlOnCompanyInformationPage(CompanyInformation.FieldNo("Registered Name"));
    end;
#endif    

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

#if not CLEAN27
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RegisteredAddressExistOnCompanyInformationPage()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of the test is to validate that Registered Address field exist on the Company Information Page.
        CheckControlOnCompanyInformationPage(CompanyInformation.FieldNo("Registered Address"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RegisteredAddress2ExistOnCompanyInformationPage()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of the test is to validate that Registered Address 2 field exist on the Company Information Page.
        CheckControlOnCompanyInformationPage(CompanyInformation.FieldNo("Registered Address 2"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RegisteredCountyExistOnCompanyInformationPage()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of the test is to validate that Registered County field exist on the Company Information Page.
        CheckControlOnCompanyInformationPage(CompanyInformation.FieldNo("Registered County"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BranchNumberExistOnCompanyInformationPage()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of the test is to validate that Branch Number field exist on the Company Information Page.
        CheckControlOnCompanyInformationPage(CompanyInformation.FieldNo("Branch Number"));
    end;
#endif

    local procedure CheckControlOnCompanyInformationPage(FieldNo: Integer)
    var
        ControlExist: Boolean;
    begin
        // Setup and Exercise: Find Control on Company Information Page with Field No.
        ControlExist := LibraryUtilityOnPrem.FindControl(1, FieldNo);  // 1 used for Company Information Page Id.

        // Verify: Verify that control exist on Company Information page.
        Assert.AreEqual(true, ControlExist, 'Control must exist');
    end;

#if not CLEAN27 
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateRegisteredCityCompanyInformationTable()
    var
        CompanyInformation: Record "Company Information";
        PostCode: Record "Post Code";
    begin
        // Purpose of the test is to validate the On Validate trigger of the Registered City field on Company Information Table.

        // Setup: Find Post Code.
        PostCode.FindFirst();

        // Exercise.
        CompanyInformation.Validate("Registered City", PostCode.City);
        CompanyInformation.Modify();

        // Verify: Verify that Registered Post Code field is populated correctly when validate the Registered City on Company Information Table.
        CompanyInformation.Get();
        CompanyInformation.TestField("Registered Post Code", PostCode.Code);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateRegisteredPostCodeCompanyInformationTable()
    var
        CompanyInformation: Record "Company Information";
        PostCode: Record "Post Code";
    begin
        // Purpose of the test is to validate the On Validate trigger of the Registered Post Code field on Company Information Table.

        // Setup: Find Post Code.
        PostCode.FindFirst();

        // Exercise.
        CompanyInformation.Validate("Registered Post Code", PostCode.Code);
        CompanyInformation.Modify();

        // Verify: Verify that Registered City field is populated correctly when validate the Registered Post Code on Company Information Table.
        CompanyInformation.Get();
        CompanyInformation.TestField("Registered City", PostCode.City);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBranchNumberThreeDigitNumericAndEmptyCompanyInformationTable()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of the test is to validate the On Validate trigger of the Branch Number field on Company Information Table.

        // Enter three digit value in Branch Number
        CompanyInformation.Validate("Branch Number", Format(LibraryRandom.RandIntInRange(100, 999)));
        CompanyInformation.Modify();

        // Verify: Verify that Branch Number field is able to blank on Company Information Table.
        CompanyInformation.Get();
        CompanyInformation.Validate("Branch Number", '');
        CompanyInformation.Modify();
    end;
#endif    
}

