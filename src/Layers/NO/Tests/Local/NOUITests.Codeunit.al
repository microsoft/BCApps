codeunit 144184 "NO UI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UI]
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure RegistrationNoFieldExistsInCompanyInformationPage()
    var
        CompanyInformation: TestPage "Company Information";
    begin
        // [SCENARIO 398121] A "Registration No." field exists in the company information pge

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        CompanyInformation.OpenView();
        Assert.IsTrue(CompanyInformation."Registration No.".Visible(), 'Registration no. field is not visible.');
        CompanyInformation.Close();

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"NO UI Tests");

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"NO UI Tests");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"NO UI Tests");
    end;
}

