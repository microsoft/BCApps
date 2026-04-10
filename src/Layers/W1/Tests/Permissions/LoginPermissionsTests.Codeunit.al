/// <summary>
/// This test verifies the LOGIN permission set can be used to log in and change language and company with BaseApp installed.
/// </summary>
codeunit 132913 "Login Permissions Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        CompanyName: Label 'Test Company';

    [Test]
    [HandlerFunctions('HandleSelectAvailableLanguages,StandardSessionSettingsHandler')]
    procedure ModifyLanguageWithLoginPermissionsOK()
    var
        WindowsLanguage: Record "Windows Language";
        UserSettingsPage: TestPage "User Settings";
    begin
        SetLanguageInUserPersonalization(1082);
        WindowsLanguage.Get(GlobalLanguage);
        Assert.IsTrue(LibraryLowerPermissions.CanLowerPermission(), 'The current user should have the ability to lower permissions.');

        LibraryLowerPermissions.SetExactPermissionSet('LOGIN');
        LibraryLowerPermissions.AddPermissionSet('Login Test - Execute');
        UserSettingsPage.OpenEdit();
        UserSettingsPage.LanguageName.AssistEdit();
        Assert.AreEqual(WindowsLanguage.Name,
          UserSettingsPage.LanguageName.Value(),
          'The Language field should change after selecting in the Lookup.');
        UserSettingsPage.OK().Invoke();
        Assert.AreEqual(WindowsLanguage.Name,
          GetLanguageFromUserPersonalization(),
          'The user''s Language should be updated in the User Personalization table after closing My Settings.');
    end;

    [Test]
    [HandlerFunctions('ChangeCompanyModalPageHandler,StandardSessionSettingsHandler')]
    procedure ChangeCompanyWithLoginPermissionsOK()
    var
        Company: Record Company;
        CompanyTriggers: Codeunit "Company Triggers";
        UserSettingsPage: TestPage "User Settings";
    begin
        Company.Name := CompanyName;
        Company.Insert();

        LibraryLowerPermissions.SetExactPermissionSet('LOGIN');
        LibraryLowerPermissions.AddPermissionSet('Login Test - Execute');

        // [WHEN] "My Settings" page is opened and company is changed with LOGIN permission set
        // [THEN] No error is thrown
        UserSettingsPage.OpenEdit();
        UserSettingsPage.Company.AssistEdit();
        UserSettingsPage.OK().Invoke(); // The new company is actually not opened because updating the session doesn't work, but this tests the flow until sessionSetting.RequestSessionUpdate(true);
                                        // Below we verify that opening a company also works with login creds (I.E. after changing the company)

        // [WHEN] Company is opened with LOGIN permission set
        // [THEN] No error is thrown
#pragma warning disable AL0432 // Function is moving onPrem but can still be called from tests
        CompanyTriggers.OnCompanyOpen();
#pragma warning restore AL0432

        // Make sure we have actually been testing with lower permissions.
        // Testing this at the end since the error will revert all transactions.
        asserterror Page.RunModal(Page::"Customer Card");
        Assert.ExpectedError('Sorry, the current permissions prevented the action. (Page 21 Customer Card Execute: Tests-Permissions)'); // Important that the error is missing execute permission, not missing tabledata permissions.

    end;

    local procedure GetLanguageFromUserPersonalization(): Text
    var
        UserPersonalization: Record "User Personalization";
        WindowsLanguage: Record "Windows Language";
    begin
        UserPersonalization.Get(UserSecurityId());
        WindowsLanguage.Get(UserPersonalization."Language ID");
        exit(WindowsLanguage.Name);
    end;

    local procedure SetLanguageInUserPersonalization(ID: Integer)
    var
        UserPersonalization: Record "User Personalization";
    begin
        UserPersonalization.Get(UserSecurityId());
        UserPersonalization."Language ID" := ID;
        UserPersonalization.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleSelectAvailableLanguages(var WindowsLanguages: Page "Windows Languages"; var Response: Action)
    var
        WindowsLanguage: Record "Windows Language";
    begin
        WindowsLanguage.Get(GlobalLanguage);
        WindowsLanguages.SetRecord(WindowsLanguage);
        Response := ACTION::LookupOK;
    end;

    [SessionSettingsHandler]
    procedure StandardSessionSettingsHandler(var TestSessionSettings: SessionSettings): Boolean
    begin
        exit(false);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeCompanyModalPageHandler(var AccessibleCompanies: TestPage "Accessible Companies")
    begin
        AccessibleCompanies.GoToKey(CompanyName);
        AccessibleCompanies.OK().Invoke();
    end;

}

