codeunit 139316 "Company Creation Wizard Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Company Creation Wizard] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        CompanyAlreadyExistsErr: Label 'A company with that name already exists. Try a different name.';
        SpecifyCompanyNameErr: Label 'To continue, you must specify a name for the company.';
        SetupNotCompletedQst: Label 'The company has not yet been created.\\Are you sure that you want to exit?';

    [Test]
    [Scope('OnPrem')]
    procedure CheckCompanySetupStatus()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        // [SCENARIO] All new companies do not have to show the setup wizard at the first login
        // [GIVEN] All types of companies
        // [THEN] The flag enabled is set to false
        Assert.AreEqual(false, AssistedCompanySetupStatus.Enabled, 'The flag should be set to false.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure WizardCheckDefaultDemoData()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CompanyCreationWizard: TestPage "Company Creation Wizard";
        NewCompanyData: Enum "Company Demo Data Type";
    begin
        // [GIVEN] Full SaaS experience is disabled
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Open Company Creation Wizard on Basic Information tab
        CompanyCreationWizard.OpenEdit();
        CompanyCreationWizard.ActionNext.Invoke(); // Basic Information page

        // [THEN] Default option is Create New - No Data
        Assert.AreEqual(
            CompanyCreationWizard.CompanyData.Value, Format(NewCompanyData::"Create New - No Data"),
            'First option should be Production - Setup Data Only.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCompanyCreatedWhenWizardCompleted()
    var
        Company: Record Company;
        CompanyCreationWizard: TestPage "Company Creation Wizard";
        NewCompanyName: Text;
    begin
        // [WHEN] The company creation wizard is completed
        NewCompanyName := LibraryUtility.GenerateRandomCode(Company.FieldNo(Name), DATABASE::Company);
        RunWizardToCompletion(CompanyCreationWizard, NewCompanyName);
        CompanyCreationWizard.ActionFinish.Invoke();

        // [THEN] A new company was created
        Assert.IsTrue(Company.Get(NewCompanyName), 'The new company was not created');
        Assert.IsFalse(IsNullGuid(Company.Id), 'An Id was not created for the new company');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WizardStopsWhenCompanyNameNotSpecified()
    var
        CompanyCreationWizard: TestPage "Company Creation Wizard";
    begin
        // [GIVEN] An openend company creation wizard on the Basic information page
        CompanyCreationWizard.Trap();
        PAGE.Run(PAGE::"Company Creation Wizard");
        CompanyCreationWizard.ActionNext.Invoke(); // Basic Information page

        // [WHEN] No company name is entered and next is pressed
        asserterror CompanyCreationWizard.ActionNext.Invoke(); // That's it page

        // [THEN] An error message is thrown, preventing the user from continuing
        Assert.ExpectedError(SpecifyCompanyNameErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WizardStopsWhenAlreadyExistingCompanyNameIsSpecified()
    var
        CompanyCreationWizard: TestPage "Company Creation Wizard";
    begin
        // [GIVEN] An openend company creation wizard on the Basic information page
        CompanyCreationWizard.Trap();
        PAGE.Run(PAGE::"Company Creation Wizard");
        CompanyCreationWizard.ActionNext.Invoke(); // Basic Information page

        // [WHEN] A company name of an already existing company is entered
        asserterror CompanyCreationWizard.CompanyName.SetValue(CompanyName);

        // [THEN] An error message is thrown, preventing the user from continuing
        Assert.ExpectedError(CompanyAlreadyExistsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TrimHeadingTrailingSpacesInNewCompanyName()
    var
        Company: Record Company;
        CompanyCreationWizard: TestPage "Company Creation Wizard";
        NewCompanyName: Text;
    begin
        // [SCENARIO 224319] Company creation wizard trims heading and trailing spaces in new company name
        NewCompanyName := LibraryUtility.GenerateRandomCode(Company.FieldNo(Name), DATABASE::Company);
        RunWizardToCompletion(CompanyCreationWizard, ' ' + NewCompanyName + ' ');
        CompanyCreationWizard.ActionFinish.Invoke();

        Company.Get(NewCompanyName);
        Company.TestField(Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WizardsSucceedsAfterDeletingAndCreatingCompanyWithSameName()
    var
        Company: Record Company;
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        CompanyCreationWizard: TestPage "Company Creation Wizard";
        NewCompanyData: Enum "Company Demo Data Type";
        NewCompanyName: Text[30];
    begin
        // [WHEN] The company creation wizard is completed
        NewCompanyName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Company.Name)), 1, MaxStrLen(Company.Name));
        RunWizardToCompletion(CompanyCreationWizard, NewCompanyName);
        CompanyCreationWizard.ActionFinish.Invoke();

        // [WHEN] The company is deleted
        Company.SetRange(Name, NewCompanyName);
        if Company.FindFirst() then
            Company.Delete(true);

        // [WHEN] The company is created again with same name
        AssistedCompanySetup.CreateNewCompany(NewCompanyName);
        AssistedCompanySetup.SetUpNewCompany(NewCompanyName, NewCompanyData::"Create New - No Data");

        // [THEN] The company was created with no errors
        Assert.IsTrue(Company.Get(NewCompanyName), 'The new company was not created');
        Assert.IsFalse(IsNullGuid(Company.Id), 'An Id was not created for the new company');
    end;

    local procedure RunWizardToCompletion(var CompanyCreationWizard: TestPage "Company Creation Wizard"; NewCompanyName: Text)
    var
        NewCompanyData: Enum "Company Demo Data Type";
    begin
        CompanyCreationWizard.Trap();
        PAGE.Run(PAGE::"Company Creation Wizard");

        CompanyCreationWizard.ActionNext.Invoke(); // Basic Information page
        CompanyCreationWizard.ActionBack.Invoke(); // Welcome page
        Assert.IsFalse(CompanyCreationWizard.ActionBack.Enabled(), 'Back should not be enabled at the beginning of the wizard');
        CompanyCreationWizard.ActionNext.Invoke(); // Basic Information page
        CompanyCreationWizard.CompanyName.SetValue(NewCompanyName);
        CompanyCreationWizard.CompanyData.SetValue(NewCompanyData::"Create New - No Data"); // Set to None to avoid lengthy data import
        CompanyCreationWizard.ActionNext.Invoke(); // Manage Users page
        CompanyCreationWizard.ActionNext.Invoke(); // That's it page
        Assert.IsTrue(CompanyCreationWizard.ActionBack.Enabled(), 'Back should be enabled at the end of the wizard');
        Assert.IsFalse(CompanyCreationWizard.ActionNext.Enabled(), 'Next should not be enabled at the end of the wizard');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HandleConfirm(Message: Text[1024]; var Reply: Boolean)
    begin
        case true of
            StrPos(Message, 'Do you want to save the encryption key?') <> 0:
                Reply := false;
            StrPos(Message, 'Enabling encryption will generate an encryption key') <> 0:
                Reply := true;
            StrPos(Message, 'Disabling encryption will decrypt the encrypted data') <> 0:
                Reply := true;
            StrPos(Message, SetupNotCompletedQst) <> 0:
                Reply := true;
            else
                Reply := false;
        end;
    end;
}
